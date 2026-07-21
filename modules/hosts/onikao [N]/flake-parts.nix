{ inputs, ... }:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "onikao";

  flake-file.inputs = {
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}