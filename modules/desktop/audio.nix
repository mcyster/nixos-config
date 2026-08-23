{ lib, config, pkgs, ... }:

let
  cfg = config.my.desktop;

  profileOpts = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Short identifier passed to `audio-profile`.";
      };
      label = lib.mkOption {
        type = lib.types.str;
        description = "Human readable name shown in the notification.";
      };
      match = lib.mkOption {
        type = lib.types.str;
        description = ''
          Extended regex matched against PipeWire/PulseAudio node names to pick
          both the sink and the source, e.g. "ATH-M50".
        '';
      };
      sinkMatch = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Overrides `match` when picking the output device.";
      };
      sourceMatch = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Overrides `match` when picking the input device.";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "audio-card";
        description = "Icon name used for the notification.";
      };
    };
  };

  # Cycle order follows the attribute name, so the identifiers double as the
  # ordering key.
  profiles = lib.attrValues cfg.audioProfiles;

  bashArray = name: values:
    "${name}=(${lib.concatMapStringsSep " " lib.escapeShellArg values})";

  bashMap = name: field:
    lib.concatStringsSep "\n" (
      [ "declare -A ${name}=()" ]
      ++ map (p: "${name}[${lib.escapeShellArg p.name}]=${lib.escapeShellArg (field p)}") profiles
    );

  audio-profile = pkgs.writeShellApplication {
    name = "audio-profile";
    runtimeInputs = [ pkgs.pulseaudio pkgs.libnotify ];
    text = ''
      ${bashArray "order" (map (p: p.name) profiles)}
      ${bashMap "labels" (p: p.label)}
      ${bashMap "sink_match" (p: if p.sinkMatch != null then p.sinkMatch else p.match)}
      ${bashMap "source_match" (p: if p.sourceMatch != null then p.sourceMatch else p.match)}
      ${bashMap "icons" (p: p.icon)}

      notify() {
        notify-send --app-name="Audio" --icon="$1" \
          --hint=string:x-canonical-private-synchronous:audio-profile \
          "$2" "''${3-}" || true
      }

      # First sink/source whose node name matches the profile's regex. Monitor
      # sources are skipped so a loopback of an output never wins.
      find_sink() {
        pactl list short sinks | awk -v p="$1" '$2 ~ p { print $2; exit }'
      }
      find_source() {
        pactl list short sources |
          awk -v p="$1" '$2 ~ p && $2 !~ /\.monitor$/ { print $2; exit }'
      }

      # The profile owning the current default sink, empty if none matches.
      current_profile() {
        local sink
        sink=$(pactl get-default-sink 2>/dev/null) || return 0
        local name
        for name in "''${order[@]}"; do
          if [[ $sink =~ ''${sink_match[$name]} ]]; then
            printf '%s\n' "$name"
            return 0
          fi
        done
      }

      apply() {
        local name=$1 sink source moved
        sink=$(find_sink "''${sink_match[$name]}")
        source=$(find_source "''${source_match[$name]}")

        if [[ -z $sink && -z $source ]]; then
          notify dialog-warning "''${labels[$name]} not connected"
          return 1
        fi

        if [[ -n $sink ]]; then
          pactl set-default-sink "$sink"
          # Existing streams stay pinned to their old device, so drag them over.
          while read -r moved; do
            if [[ -n $moved ]]; then
              pactl move-sink-input "$moved" "$sink" || true
            fi
          done < <(pactl list short sink-inputs | cut -f1)
        fi

        if [[ -n $source ]]; then
          pactl set-default-source "$source"
          while read -r moved; do
            if [[ -n $moved ]]; then
              pactl move-source-output "$moved" "$source" || true
            fi
          done < <(pactl list short source-outputs | cut -f1)
        fi

        local detail=""
        if [[ -z $sink ]]; then
          detail="output unavailable"
        elif [[ -z $source ]]; then
          detail="microphone unavailable"
        fi
        notify "''${icons[$name]}" "''${labels[$name]}" "$detail"
      }

      # The profile after the current one, wrapping around; the first profile
      # when nothing matches (e.g. audio is on HDMI or the built-in card).
      next_profile() {
        local current i
        current=$(current_profile)
        for i in "''${!order[@]}"; do
          if [[ ''${order[i]} == "$current" ]]; then
            printf '%s\n' "''${order[(i + 1) % ''${#order[@]}]}"
            return 0
          fi
        done
        printf '%s\n' "''${order[0]}"
      }

      usage() {
        printf 'usage: audio-profile [--next|--list|--current|<profile>]\n\n'
        printf 'profiles:\n'
        local name
        for name in "''${order[@]}"; do
          printf '  %-14s %s\n' "$name" "''${labels[$name]}"
        done
      }

      case "''${1---next}" in
        --next|-n) apply "$(next_profile)" ;;
        --list|-l) usage ;;
        --current|-c) current_profile ;;
        --help|-h) usage ;;
        *)
          if [[ -v "labels[$1]" ]]; then
            apply "$1"
          else
            printf 'audio-profile: unknown profile %s\n\n' "$1" >&2
            usage >&2
            exit 1
          fi
          ;;
      esac
    '';
  };

  # Cycling is the default action, so the toggle is just a friendlier name.
  audio-toggle = pkgs.writeShellScriptBin "audio-toggle" ''
    exec ${lib.getExe audio-profile} "$@"
  '';

  # Makes the toggle reachable from the GNOME overview, not just a terminal.
  audio-toggle-desktop = pkgs.makeDesktopItem {
    name = "audio-toggle";
    desktopName = "Toggle Audio Device";
    comment = "Switch speaker and microphone between ${
      lib.concatMapStringsSep " and " (p: p.label) profiles
    }";
    exec = "audio-toggle";
    icon = "audio-headset";
    categories = [ "Settings" "Audio" ];
    keywords = [ "sound" "audio" "headphones" "microphone" "speaker" ];
  };
in
{
  options.my.desktop.audioProfiles = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule profileOpts);
    default = { };
    description = ''
      Named output+input device pairs that `audio-toggle` cycles through.
      Devices that are not connected are skipped with a notification.
    '';
  };

  config = lib.mkIf cfg.enable {
    my.desktop.audioProfiles = {
      headphones = {
        label = "Headphones (ATH-M50)";
        match = "ATH-M50";
        icon = "audio-headset";
      };
      speaker = {
        label = "Speakerphone (Jabra SPEAK 510)";
        match = "Jabra_SPEAK_510";
        icon = "audio-speakers";
      };
    };

    environment.systemPackages = [
      pkgs.pulseaudio # pactl, for scripting PipeWire's Pulse layer
      audio-profile
      audio-toggle
      audio-toggle-desktop
    ];
  };
}
