{ inputs, ... }:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "skyloft";

  flake-file.inputs = {
    disko = {
      url    = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}