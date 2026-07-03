{ config, pkgs, ... }:

{
  networking.hostName = "bootstrap"; # change if you want

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.wal = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    nh
  ];

  services.openssh.enable = true;

  system.stateVersion = "25.11";
}
