{ lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = false;
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];

  networking.hostName = "roo";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];

  zramSwap.enable = true;

  my.users = {
    wal = { isAdmin = true; };
  };

  users.users.wal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0KTSn9pm04mSnRO/cjJJ2fmF0EVrDefd9ujYDlpDJY opencode-temp-linode"
  ];

  system.stateVersion = "26.11";
}
