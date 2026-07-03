{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    tcpdump
    acpi
    dmidecode
    pciutils
    lshw
    lsof
    vim
    git
    jq
    wget
    zip
    unzip
    usbutils

    direnv
    opencode

    

    gimp
    google-chrome

    miller

    

    cursor-cli
    code-cursor
    ripgrep
    mdcat

    zoom-us

    nvd
    nix-index
    comma
    btop
  ];

  programs.nh = {
    enable = true;
    flake = "/home/wal/nixos-config";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  virtualisation.docker.enable = true;
  users.users.wal = {
    isNormalUser = true;
    description = "wal";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };


  users.users.leona = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.extraRules = [
    {
      users = [ "wal" ];
      commands = [
        { command = "ALL"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  services.smartd.enable = true;

  services.tailscale.enable = true;

  environment.variables.EDITOR = lib.mkForce "vim";
}
