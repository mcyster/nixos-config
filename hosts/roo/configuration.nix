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
