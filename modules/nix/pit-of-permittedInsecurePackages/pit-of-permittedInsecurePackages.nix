let
  sharedLogic = { lib, ... }: {
    # nixpkgs.config.permittedInsecurePackages =
    #   (lib.optionals (lib.versionOlder lib.version "26.05") [ "luanti-5.14.0" ]) # Only allow these insecure packages on NixOS versions older than 26.05.
    #   ++ (lib.optionals (lib.versionOlder lib.version "26.11") [ "electron-40.10.5" ]);
    
    nixpkgs.config.allowInsecurePredicate = _: true; # allow all insecure packages
  };
in
{
  # Assign the same logic to the correct class namespaces so the Nix module system accepts them
  flake.modules.nixos.pit-of-permittedInsecurePackages       = sharedLogic;
  flake.modules.homeManager.pit-of-permittedInsecurePackages = sharedLogic;
  flake.modules.darwin.pit-of-permittedInsecurePackages      = sharedLogic;
}