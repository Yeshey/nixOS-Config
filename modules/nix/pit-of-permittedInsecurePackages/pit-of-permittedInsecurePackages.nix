let
  sharedLogic = { lib, ... }: {
    # nixpkgs.config.permittedInsecurePackages =
    #   (lib.optionals (lib.versionOlder lib.version "26.05") [ "luanti-5.14.0" ]) # Only allow these insecure packages on NixOS versions older than 26.05.
    #   ++ (lib.optionals (lib.versionOlder lib.version "26.11") [ "electron-40.10.5" ]);

    nixpkgs.config.allowInsecurePredicate = _: true; # allow all insecure packages

    # ── fastmcp: disable test suite ───────────────────────────────
    # was failing in github action
    nixpkgs.overlays = [
      (final: prev: {
        python3Packages = prev.python3Packages.overrideScope (
          pyself: pysuper: {
            fastmcp = pysuper.fastmcp.overridePythonAttrs (_old: {
              doCheck = false;
              doInstallCheck = false;
            });
          }
        );
      })
    ];

  };
in
{
  flake.modules.nixos.pit-of-permittedInsecurePackages       = sharedLogic;
  flake.modules.homeManager.pit-of-permittedInsecurePackages = sharedLogic;
  flake.modules.darwin.pit-of-permittedInsecurePackages      = sharedLogic;
}