# hashes come from from common/default.nix in your nixos-hardware input
# So I don't have to rebuild the kernel every time.
{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:

let
  pkgs-kernel = import inputs.nixpkgs-kernel {
    system = pkgs.stdenv.hostPlatform.system;
    config = { allowUnfree = true; };  # explicit nixpkgs config, not NixOS config
  };

  # Everything below is copy-pasted from common/default.nix,
  # just with pkgs-kernel instead of pkgs:
  srcVersion = "6.18.7";
  srcHash = "sha256-tyak0Vz5rgYhm1bYeCB3bjTYn7wTflX7VKm5wwFbjx4=";

  linux-surface = pkgs-kernel.fetchFromGitHub {
    owner = "linux-surface";
    repo = "linux-surface";
    rev = "7d273267d9af19b3c6b2fdc727fad5a0f68b1a3d";
    hash = "sha256-CPY/Pxt/LTGKyQxG0CZasbvoFVbd8UbXjnBFMnFVm9k=";
  };

  inherit (pkgs-kernel.callPackage "${inputs.nixos-hardware}/microsoft/surface/common/kernel/linux-package.nix" { })
    linuxPackage
    surfacePatches
    ;

  kernelPatches = surfacePatches {
    version = srcVersion;
    patchFn = "${inputs.nixos-hardware}/microsoft/surface/common/kernel/6.18/patches.nix";
    patchSrc = "${linux-surface}/patches/6.18";
  };
in
{
  boot.kernelPackages = lib.mkForce (linuxPackage {
    inherit kernelPatches;
    version = srcVersion;
    sha256 = srcHash;
    ignoreConfigErrors = true;
  });
  boot.extraModulePackages = lib.mkForce [ 
    config.boot.kernelPackages.bcachefs  # uses pkgs-kernel's bcachefs via kernelPackages
  ];

  boot.supportedFilesystems = [ "bcachefs" ];
}
