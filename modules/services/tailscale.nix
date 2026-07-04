{ lib, config, ... }:

let
  cfg = config.my.services.tailscale;
in
{
  options.my.services.tailscale.enable = lib.mkEnableOption "Tailscale";

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;
  };
}
