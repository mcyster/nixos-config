{
  description = "My NixOS configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      moaWorkModule = self.outPath + "/.private/moa/extole.nix";

      mkHost = modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules =
            [
              home-manager.nixosModules.home-manager
              ./modules/home
              ./modules/base
              ./modules/desktop/gnome.nix
              ./modules/dev
              ./modules/games
              ./modules/services/tailscale.nix
              ./modules/virtualisation/docker.nix
            ]
            ++ modules;
        };
    in {
      nixosConfigurations = {
        fox = mkHost [ ./hosts/fox/configuration.nix ];
        moa = mkHost [
          ./hosts/moa/configuration.nix
          (if builtins.pathExists moaWorkModule then moaWorkModule else {
            assertions = [{
              assertion = false;
              message = ''
                moa requires the local Extole configuration. Run
                ./scripts/sync-moa-work-config, then evaluate this flake as
                path:/home/mcyster/nixos-config.
              '';
            }];
          })
        ];
        roo = mkHost [ ./hosts/roo/configuration.nix ];
      };
    };
}
