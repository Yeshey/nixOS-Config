# So I don't have to rebuild the kernel every time.
# To update: bump nixpkgs-kernel.url hash in flake-parts.nix
# and nixos-hardware.url if needed — that's it.
{ inputs, ... }:
{
  flake.modules.nixos.kakariko =
    { pkgs, lib, config, ... }:
    let
      pkgs-kernel = import inputs.nixpkgs-kernel {
        system       = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };

      # Call the surface module directly with pkgs-kernel injected
      # so the kernel package comes from the pinned nixpkgs, not current nixpkgs.
      # This avoids rebuilding the kernel on every nixpkgs bump.
      surfaceModule = import
        "${inputs.nixos-hardware}/modules/microsoft/surface/common/default.nix";

      surfaceResult = surfaceModule {
        inherit lib;
        pkgs   = pkgs-kernel;
        config = {
          hardware.microsoft-surface.kernelVersion = "stable";
        };
      };
    in
    {
      boot.kernelPackages    = lib.mkForce surfaceResult.config.boot.kernelPackages;
      boot.extraModulePackages = lib.mkForce [
        config.boot.kernelPackages.bcachefs
      ];
    };
}