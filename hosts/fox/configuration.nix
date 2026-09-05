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

  environment.systemPackages =
    let
      zed-wrapped = pkgs.symlinkJoin {
        name = "zed-editor-wrapped";
        paths = [ pkgs.zed-editor ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/zeditor --run 'export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-0}"'
        '';
      };
    in
    [
      zed-wrapped
    ];


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
      wal = {
        isAdmin = true;
        extraGroups = [ "docker" ];
      };
      leona = { };
    };

    desktop.enable = true;
    dev.enable = true;
    games.enable = true;

    virtualisation.docker.enable = true;
  };

  home-manager.users.wal = import ../../modules/home/users/wal.nix;
}
