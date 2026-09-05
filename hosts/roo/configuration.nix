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
      PermitRootLogin = "no";
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
    "d /srv/game1 0750 game1 game1 - -"
    "d /srv/game1/releases 0770 game1 game1 - -"
    "d /srv/game1/backups 0770 game1 game1 - -"
    "d /srv/game1/shared 0770 game1 game1 - -"
    "d /srv/game1/shared/instance 0770 game1 game1 - -"
  ];

  users.groups.game1 = { };
  users.users.game1 = {
    isSystemUser = true;
    group = "game1";
    home = "/var/lib/game1";
    createHome = true;
  };

  systemd.services.game1 = {
    description = "Plant Collector Flask app";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/srv/game1/current/scripts/wsgi.py";
    serviceConfig = {
      User = "game1";
      Group = "game1";
      WorkingDirectory = "/srv/game1/current";
      EnvironmentFile = "/srv/game1/shared/game1.env";
      Environment = [
        "HOME=/var/lib/game1"
        "XDG_CACHE_HOME=/var/cache/game1"
      ];
      ExecStart = "${pkgs.nix}/bin/nix develop --command gunicorn --bind 127.0.0.1:8001 --workers 2 scripts.wsgi:app";
      Restart = "on-failure";
      RestartSec = 5;
      StateDirectory = "game1";
      CacheDirectory = "game1";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/srv/game1/shared/instance" ];
      RestrictSUIDSGID = true;
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
    unitConfig.ConditionPathIsExecutable = "/srv/game1/current/scripts/g-backup";
    path = with pkgs; [
      bash
      coreutils
      findutils
      gnutar
      gzip
      python3
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "game1";
      Group = "game1";
      WorkingDirectory = "/srv/game1/current";
      ExecStart = "/srv/game1/current/scripts/g-backup";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/srv/game1/backups" ];
      RestrictSUIDSGID = true;
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 90d";
  };

  security.sudo.wheelNeedsPassword = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];

  zramSwap.enable = true;

  my.users = {
    wal = {
      isAdmin = true;
      extraGroups = [ "game1" ];
    };
  };

  home-manager.users.wal = import ../../modules/home/users/wal.nix;

  system.stateVersion = "26.11";
}
