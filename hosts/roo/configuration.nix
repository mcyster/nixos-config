{ lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = false;
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];

  networking.hostName = "roo";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  services.httpd = {
    enable = true;
    adminAddr = "webmaster@localhost";
    extraModules = [ "proxy" "proxy_http" ];
    virtualHosts."cyster.com" = {
      documentRoot = "/srv/www/cyster.com/public";
      enableACME = true;
      forceSSL = true;
      serverAliases = [ "www.cyster.com" ];
    };
    virtualHosts."plants.cyster.com" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        ProxyPreserveHost On
        ProxyPass / http://127.0.0.1:8001/
        ProxyPassReverse / http://127.0.0.1:8001/
      '';
    };
  };

  security.acme = {
    acceptTerms = true;
  };

  systemd.tmpfiles.rules = [
    "d /srv/www 0755 root root - -"
    "d /srv/www/cyster.com 0755 wal users - -"
    "d /srv/www/cyster.com/public 0755 wal users - -"
    "d /srv/game1 0755 wal users - -"
    "d /srv/game1/releases 0755 wal users - -"
    "d /srv/game1/backups 0750 wal users - -"
    "d /srv/game1/shared 0750 wal users - -"
    "d /srv/game1/shared/instance 0755 wal users - -"
  ];

  systemd.services.game1 = {
    description = "Plant Collector Flask app";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/srv/game1/current/scripts/wsgi.py";
    serviceConfig = {
      User = "wal";
      Group = "users";
      WorkingDirectory = "/srv/game1/current";
      EnvironmentFile = "/srv/game1/shared/game1.env";
      ExecStart = "${pkgs.nix}/bin/nix develop --command gunicorn --bind 127.0.0.1:8001 --workers 2 scripts.wsgi:app";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.timers.game1-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:15:00";
      Persistent = true;
    };
  };

  systemd.services.game1-backup = {
    description = "Back up Plant Collector shared state";
    unitConfig.ConditionPathIsDirectory = "/srv/game1/shared";
    path = with pkgs; [
      coreutils
      findutils
      gnutar
      gzip
      python3
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "wal";
      Group = "users";
    };
    script = ''
      set -euo pipefail

      application_directory=/srv/game1
      shared_directory="$application_directory/shared"
      instance_directory="$shared_directory/instance"
      backups_directory="$application_directory/backups"

      timestamp=$(date -u +%Y%m%d%H%M%S)
      archive="$backups_directory/game1-$timestamp.tar.gz"
      temporary_directory=$(mktemp -d)
      cleanup() { rm -rf "$temporary_directory"; }
      trap cleanup EXIT

      mkdir -p "$backups_directory"
      mkdir -p "$temporary_directory/shared"
      cp -a "$shared_directory/." "$temporary_directory/shared/"

      database_file="$instance_directory/plants.db"
      snapshot_file="$temporary_directory/shared/instance/plants.db"
      if [ -f "$database_file" ]; then
        rm -f "$snapshot_file" "$snapshot_file-wal" "$snapshot_file-shm"
        python - "$database_file" "$snapshot_file" <<'PY'
      import sqlite3
      import sys

      source_path, snapshot_path = sys.argv[1], sys.argv[2]
      with sqlite3.connect(f"file:{source_path}?mode=ro", uri=True) as source:
          with sqlite3.connect(snapshot_path) as snapshot:
              source.backup(snapshot)
      PY
        python - "$snapshot_file" <<'PY'
      import sqlite3
      import sys

      with sqlite3.connect(sys.argv[1]) as connection:
          result = connection.execute("PRAGMA integrity_check").fetchone()
      raise SystemExit(0 if result and result[0] == "ok" else 1)
      PY
      fi

      printf '%s\n' \
        "created_at_utc=$timestamp" \
        "application_directory=$application_directory" \
        "shared_directory=$shared_directory" \
        "source_host=$(hostname)" \
        > "$temporary_directory/manifest.txt"

      tar -C "$temporary_directory" -czf "$archive" shared manifest.txt
      chmod 600 "$archive"

      mapfile -t backup_files < <(find "$backups_directory" -maxdepth 1 -type f -name 'game1-*.tar.gz' | sort -r)
      for backup_file in "''${backup_files[@]:14}"; do
        rm -f "$backup_file"
      done

      printf '%s\n' "$archive"
    '';
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];

  zramSwap.enable = true;

  my.users = {
    wal = { isAdmin = true; };
  };

  system.stateVersion = "26.11";
}
