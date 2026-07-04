{ lib, config, pkgs, ... }:

let
  cfg = config.my.desktop;
in
{
  options.my.desktop.enable = lib.mkEnableOption "GNOME desktop";

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    environment.systemPackages = with pkgs; [
      firefox
      google-chrome
    ];
  };
}
