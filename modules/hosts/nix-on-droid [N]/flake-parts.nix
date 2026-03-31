{ inputs, ... }:
{
  flake.nixOnDroidConfigurations = inputs.self.lib.mkNixOnDroid "nix-on-droid";
  flake-file.inputs.nix-on-droid = {
    url = "github:nix-community/nix-on-droid/release-24.05";
  };
}