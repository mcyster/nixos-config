{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tmux
    ngrok
    python3
    eclipses.eclipse-sdk
  ];
}
