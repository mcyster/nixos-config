{ lib, config, pkgs, ... }:

let
  cfg = config.my.services.netwatch;

  hopList = lib.concatStringsSep " "
    (lib.mapAttrsToList (name: addr: "${name}:${addr}") cfg.hops);

  netwatch = pkgs.writeShellApplication {
    name = "netwatch";

    runtimeInputs = with pkgs; [
      iputils
      iproute2
      bind.dnsutils
      wireguard-tools
      coreutils
      gawk
    ];

    # The probe loop must survive failing probes, so errexit is dropped.
    bashOptions = [ "nounset" "pipefail" ];

    text = ''
      interval=${toString cfg.interval}
      stall=${toString cfg.stallThreshold}
      wan=${cfg.wanTarget}
      internal_dns=${cfg.internalDns}
      internal_name=${cfg.internalName}
      heartbeat=${toString cfg.heartbeatSeconds}

      # ICMP reachability; echoes ok or LOSS.
      probe_icmp() {
        if ping -c 1 -W 2 "$1" >/dev/null 2>&1; then
          echo ok
        else
          echo LOSS
        fi
      }

      # DNS query against an explicit server; echoes ok/<ms> or TIMEOUT.
      probe_dns() {
        local start end
        start=$(date +%s%N)
        if dig +tries=1 +time=3 +short "@$1" "$2" >/dev/null 2>&1; then
          end=$(date +%s%N)
          echo "ok/$(( (end - start) / 1000000 ))ms"
        else
          echo TIMEOUT
        fi
      }

      # Seconds since each WireGuard peer last completed a handshake. A healthy
      # tunnel with persistent-keepalive rehandshakes well inside ~180s.
      wg_ages() {
        local dev now hs age out
        out=""
        now=$(date +%s)
        for dev in ${lib.concatStringsSep " " cfg.wireguardInterfaces}; do
          while read -r _ hs; do
            [ -z "''${hs:-}" ] && continue
            if [ "$hs" = "0" ]; then
              age=never
            else
              age="$(( now - hs ))s"
            fi
            out="''${out}''${dev}=''${age} "
          done < <(wg show "$dev" latest-handshakes 2>/dev/null)
        done
        echo "''${out:-none}"
      }

      gw=$(ip route show default | awk '/default/ { print $3; exit }')
      echo "netwatch: started interval=''${interval}s gateway=''${gw:-none} wan=$wan dns=$internal_dns"

      last_beat=$(date +%s)

      while true; do
        now=$(date +%s)

        # Re-read the gateway each pass; it changes if DHCP reconfigures.
        gw=$(ip route show default | awk '/default/ { print $3; exit }')
        if [ -z "''${gw:-}" ]; then
          gw_state=NO-DEFAULT-ROUTE
        else
          gw_state=$(probe_icmp "$gw")
        fi

        # Walk the chain outward. The first hop that fails is the boundary of
        # the fault, which is what separates "my router" from "provider modem"
        # from "provider".
        hops_line=""
        hops_bad=0
        for entry in ${hopList}; do
          hop_name=''${entry%%:*}
          hop_addr=''${entry##*:}
          hop_state=$(probe_icmp "$hop_addr")
          hops_line="''${hops_line} ''${hop_name}=''${hop_state}"
          if [ "$hop_state" != ok ]; then
            hops_bad=1
          fi
        done

        wan_state=$(probe_icmp "$wan")
        dns_state=$(probe_dns "$internal_dns" "$internal_name")
        carrier=$(cat /sys/class/net/${cfg.interface}/operstate 2>/dev/null || echo unknown)

        line="route=''${gw:-none}/''${gw_state}''${hops_line} wan=''${wan_state}"
        line="''${line} dns=''${dns_state} link=''${carrier} wg=$(wg_ages)"

        if [ "$gw_state" != ok ] || [ "$hops_bad" -ne 0 ] || [ "$wan_state" != ok ] ||
           [ "$dns_state" = TIMEOUT ] || [ "$carrier" != up ]; then
          echo "netwatch: ANOMALY $line"
        elif [ "$(( now - last_beat ))" -ge "$heartbeat" ]; then
          echo "netwatch: ok $line"
          last_beat=$now
        fi

        # Time the sleep alone. Total loop time is useless for stall detection
        # because timing-out probes inflate it on exactly the passes that
        # matter; a sleep that overshoots is descheduling, i.e. a real stall.
        sleep_start=$(date +%s)
        sleep "$interval"
        overshoot=$(( $(date +%s) - sleep_start - interval ))
        if [ "$overshoot" -gt "$stall" ]; then
          echo "netwatch: LOCAL-STALL sleep overshot by ''${overshoot}s (machine stalled, not the link)"
        fi
      done
    '';
  };
in
{
  options.my.services.netwatch = {
    enable = lib.mkEnableOption "network freeze/outage watchdog";

    interval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description = "Seconds between probe passes.";
    };

    stallThreshold = lib.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = ''
        Seconds of sleep overshoot above which the machine is considered to
        have stalled locally rather than merely lost the network.
      '';
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "eno1";
      description = "Interface whose carrier state is sampled.";
    };

    wanTarget = lib.mkOption {
      type = lib.types.str;
      default = "8.8.8.8";
      description = "Off-LAN IP probed by ICMP, addressed numerically to bypass DNS.";
    };

    hops = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        router = "192.168.50.1";
        modem = "192.168.1.254";
      };
      description = ''
        Ordered-by-name hops between this host and the internet, probed by ICMP
        each pass so an outage can be attributed to a specific segment.
      '';
    };

    internalDns = lib.mkOption {
      type = lib.types.str;
      default = "10.1.0.2";
      description = "Internal resolver reached over the VPN.";
    };

    internalName = lib.mkOption {
      type = lib.types.str;
      default = "ec2.internal";
      description = "Name resolved against the internal resolver.";
    };

    heartbeatSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 300;
      description = "Seconds between healthy-state log lines.";
    };

    wireguardInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "vpn-prod" "vpn-dev" ];
      description = "WireGuard interfaces whose handshake ages are sampled.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.netwatch = {
      description = "Network freeze/outage watchdog";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = lib.getExe netwatch;
        Restart = "always";
        RestartSec = 5;
        # Root is required to read WireGuard handshake state.
        User = "root";
        Nice = 10;
      };
    };
  };
}
