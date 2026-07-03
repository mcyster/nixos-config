{
  description = "My NixOS configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      fox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./hosts/fox/configuration.nix ];
      };
    };
  };
}
