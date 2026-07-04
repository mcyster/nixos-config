{
  description = "My NixOS configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";

      mkHost = modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules =
            [
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
        roo = mkHost [ ./hosts/roo/configuration.nix ];
      };
    };
}
