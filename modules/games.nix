{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    prismlauncher
  ];

  programs.steam.enable = true;
}
