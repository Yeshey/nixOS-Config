{
  flake-file.inputs.nix-luanti = {
    url = "github:minetest/nix-luanti"; # adjust to the actual flake URL you use
    inputs.nixpkgs.follows = "nixpkgs";
  };
}