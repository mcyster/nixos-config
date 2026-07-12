{ lib, pkgs, ... }:

let
  dockerPackage = pkgs.docker_29.override {
    version = "29.5.2";
    cliRev = "v29.5.2";
    cliHash = "sha256-kHgDZVr6mAyCtZ6bSG9FWV0GhWDfXLXzHYFrmjFzO9w=";
    mobyRev = "docker-v29.5.2";
    mobyHash = "sha256-lux7tTyF6vm5wuIXs+z3Ygd2v4JjgHbRvOXNA4kjNtg=";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./hardware-my.nix
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    devices = [ "nodev" ];
  };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  networking.hostName = "moa";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  services.gnome.gcr-ssh-agent.enable = true;

  services.flatpak.enable = true;
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

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.trusted-users = [ "root" "mcyster" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 90d";
  };

  programs.nh.flake = lib.mkForce "path:/home/mcyster/nixos-config";

  environment.systemPackages = with pkgs; [
    mtr
    traceroute
    tcpdump
    procps
    psmisc
    file
    which
    tmux
    screen
    miller
    ngrok
    wl-clipboard
    python3
    poetry
    gimp
    yad
    eclipses.eclipse-sdk
    code-cursor
    mdcat
    zoom-us
    nvd
    nix-index
    comma
  ];

  virtualisation.docker.package = dockerPackage;

  # The Extole module owns this account; these settings preserve its current UID
  # and add machine-specific groups.
  users.users.mcyster = {
    uid = 1000;
    group = lib.mkForce "users";
    extraGroups = [ "docker" "networkmanager" ];
  };

  services.smartd.enable = true;
  environment.variables.EDITOR = lib.mkForce "vim";
  zramSwap.enable = true;

  system.stateVersion = "25.11";

  my = {
    users = {
      wal = {
        isAdmin = true;
        extraGroups = [ "networkmanager" "docker" ];
      };
      bsmith.isAdmin = true;
    };

    desktop.enable = true;
    dev.enable = true;
    virtualisation.docker.enable = true;
  };
}
