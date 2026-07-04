{ lib, config, pkgs, ... }:

let
  cfg = config.my.users;
  walAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWiPdhC/VTekihutDANEWz+TCoQkuqHawN02aNdwrCE wal@fox"
  ];
in
{
  options.my.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        isAdmin = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
      };
    }));
    default = {};
  };

  config = {
    users.users = lib.mapAttrs (name: userCfg: {
      isNormalUser = true;
      extraGroups =
        (if userCfg.isAdmin then [ "wheel" ] else [])
        ++ userCfg.extraGroups;
      openssh.authorizedKeys.keys = lib.optionals (name == "wal") walAuthorizedKeys;
    }) cfg;
  };
}
