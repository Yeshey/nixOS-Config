{ inputs, ... }:
{
  flake-file.inputs = {
    nixpkgs2flatpak = {
      url    = "github:Yeshey/nixpkgs2flatpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}