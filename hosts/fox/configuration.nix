{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./minecraft-kingdom4.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "fox";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb.layout = "us";

  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };


  nixpkgs.config.allowUnfree = true;


  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.stateVersion = "25.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 90d";
  };

  zramSwap.enable = true;

  # New modular config
  my = {
    users = {
      wal = { isAdmin = true; };
      leona = { };
    };

    desktop.enable = true;
    dev.enable = true;
    games.enable = true;

    services.tailscale.enable = true;
    virtualisation.docker.enable = true;
  };
}
