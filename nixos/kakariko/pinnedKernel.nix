# So I don't have to rebuild the kernel every time.
# Now to update the kernel in the surface, just manually update the nixpkgs-kernel flake input and the nixos-hardware flake input as well!
{ inputs, pkgs, lib, config, ... }:
let
  pkgs-kernel = import inputs.nixpkgs-kernel {
    system = pkgs.stdenv.hostPlatform.system;
    config = { allowUnfree = true; };
  };

  # Instead of copy-pasting common/default.nix, we CALL it directly
  # with pkgs-kernel injected. It returns { options = ...; config = ...; }
  surfaceModule = import "${inputs.nixos-hardware}/microsoft/surface/common/default.nix";
  surfaceResult = surfaceModule {
    inherit lib;
    pkgs = pkgs-kernel;  # <-- the whole point
    config = {
      hardware.microsoft-surface.kernelVersion = "stable";
    };
  };
in
{
  boot.kernelPackages = lib.mkForce surfaceResult.config.boot.kernelPackages;
  boot.extraModulePackages = lib.mkForce [
    config.boot.kernelPackages.bcachefs
  ];
}