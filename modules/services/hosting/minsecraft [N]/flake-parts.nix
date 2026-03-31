{ ... }:
{
  flake-file.inputs.nix-minecraft = {
    url = "github:Yeshey/nix-minecraft";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
}