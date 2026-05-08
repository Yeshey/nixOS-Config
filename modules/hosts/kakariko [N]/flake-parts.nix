{
  inputs,
  ...
}:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "kakariko";
  flake-file.inputs.nixos-hardware = { url = "github:NixOS/nixos-hardware"; };
  flake-file.inputs.nixpkgs-kernel.url = "github:NixOS/nixpkgs/4782f433368710c4fd512c91375b9900ffda22a8";
}