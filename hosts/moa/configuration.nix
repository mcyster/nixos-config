{ lib, pkgs, ... }:

let
  poetryPackage = pkgs.poetry.overridePythonAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [
      "test_execute_executes_a_batch_of_operations"
      "test_execute_prints_warning_for_yanked_package"
    ];
  });
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
    poetryPackage
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

  virtualisation.docker.package = pkgs.docker_29;

  # The Extole module owns this account; these settings preserve its current UID
  # and add machine-specific groups.
  users.users.mcyster = {
    uid = 1000;
    isNormalUser = true;
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
