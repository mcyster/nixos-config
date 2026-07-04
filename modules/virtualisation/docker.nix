{ lib, config, ... }:

let
  cfg = config.my.virtualisation.docker;
in
{
  options.my.virtualisation.docker.enable = lib.mkEnableOption "Docker";

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
  };
}
