{
  inputs,
  ...
}:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "hyrulecastle";
  flake-file.inputs.nixos-hardware = {
    url = "github:NixOS/nixos-hardware/master";
  };
}