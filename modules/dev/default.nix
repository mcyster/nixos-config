{ lib, config, pkgs, ... }:

let
  cfg = config.my.dev;
in
{
  options.my.dev.enable = lib.mkEnableOption "development tools";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      ripgrep
      fd
      neovim
      sops
      age
      ssh-to-age
      gnupg
      pass
    ];
  };
}
