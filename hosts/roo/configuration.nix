{ lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = false;
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];

  networking.hostName = "roo";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [ 22 80 ];

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
    virtualHosts."cyster.com" = {
      documentRoot = "/srv/www/cyster.com/public";
      serverAliases = [ "www.cyster.com" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/www 0755 root root - -"
    "d /srv/www/cyster.com 0755 wal users - -"
    "d /srv/www/cyster.com/public 0755 wal users - -"
  ];

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
