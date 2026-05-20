{
  inputs,
  ...
}:
{
  flake-file.inputs.nix-luanti = {
    url = "gitlab:leonard/nix-luanti?host=git.menzel.lol";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake = {
    overlays.nix-luanti = inputs.nix-luanti.overlays.default;
  };
}