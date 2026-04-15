{
  inputs,
  ...
}:
{
  # Stage a NixOS system update on every scheduled shutdown
  # https://github.com/yeshey/nixos-upgrade-on-shutdown

  flake-file.inputs = {
    nixos-upgrade-on-shutdown.url = "github:yeshey/nixos-upgrade-on-shutdown";
    nixos-upgrade-on-shutdown.inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ inputs.nixos-upgrade-on-shutdown.flakeModules.default ];
}
