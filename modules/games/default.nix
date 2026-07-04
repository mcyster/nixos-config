{ lib, config, pkgs, ... }:

let
  cfg = config.my.games;
in
{
  options.my.games.enable = lib.mkEnableOption "gaming tools";

  config = lib.mkIf cfg.enable {
    programs.steam.enable = true;
    environment.systemPackages = with pkgs; [
      prismlauncher
    ];
  };
}
