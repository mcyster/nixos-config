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
    curl
  ];

  services.openssh.enable = true;

  # NOTE: adjust this per machine. It should match the original install version.
  system.stateVersion = "25.11";
}
