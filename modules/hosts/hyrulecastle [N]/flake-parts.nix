{
  inputs,
  ...
}:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "hyrulecastle";
  flake-file.inputs.nixos-hardware = { url = "github:mexisme/nixos-hardware/microsoft-surface/update-kernel-6.18.13"; };
  # flake-file.inputs.nixos-hardware = { url = "github:NixOS/nixos-hardware/master"; };
}