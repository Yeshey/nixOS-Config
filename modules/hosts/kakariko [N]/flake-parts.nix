{
  inputs,
  ...
}:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "kakariko";
  flake-file.inputs.nixos-hardware = { url = "github:mexisme/nixos-hardware/microsoft-surface/update-kernel-6.18.13"; };
  flake-file.inputs.nixpkgs-kernel.url = "github:NixOS/nixpkgs/98d6950e15f36939b41fb9091dd597b5054ac101";
}