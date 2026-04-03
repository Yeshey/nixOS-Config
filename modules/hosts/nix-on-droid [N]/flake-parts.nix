{ inputs, ... }:
{
  flake.nixOnDroidConfigurations = inputs.self.lib.mkNixOnDroid "nix-on-droid";
  flake-file.inputs.nix-on-droid = {
    url = "github:Yeshey/nix-on-droid/release-24.05";
    inputs.home-manager.follows = "home-manager";
  };
}
