{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
      user = "yeshey";
    in {
      nixosConfigurations = {
        ${user} = lib.nixosSystem {
          inherit system;
          modules = [ ./configuration.nix ];

        };
      };
    };

}
