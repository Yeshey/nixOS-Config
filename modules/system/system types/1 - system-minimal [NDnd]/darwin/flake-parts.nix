{
  inputs,
  ...
}:
{
  # Manage your macOS using Nix
  # https://github.com/nix-darwin/nix-darwin

  flake-file.inputs = {
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };
}
