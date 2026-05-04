let
  # Define the logic once here
  sharedLogic = { lib, ... }: {
    # Only allow these insecure packages on NixOS versions older than 26.05.
    nixpkgs.config.permittedInsecurePackages = lib.optionals (lib.versionOlder lib.version "26.05") [
      "luanti-5.14.0"
    ];
  };
in
{
  # Assign the same logic to the correct class namespaces so the Nix module system accepts them
  flake.modules.nixos.pit-of-permittedInsecurePackages       = sharedLogic;
  flake.modules.homeManager.pit-of-permittedInsecurePackages = sharedLogic;
  flake.modules.darwin.pit-of-permittedInsecurePackages      = sharedLogic;
}