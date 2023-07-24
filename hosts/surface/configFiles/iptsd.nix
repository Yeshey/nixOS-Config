{ config, pkgs, user, location, dataStoragePath, lib, ... }:

let
  
in
{
  imports = [
    <nixos-hardware/microsoft/surface>
  ];

  boot.extraModulePackages = [
    config.boot.kernelPackages.ithc
  ];

  boot.initrd.kernelModules = [
    "surface_hid_core"
    "surface_hid"
    "surface_aggregator_registry"
    "surface_aggregator"
    "8250_dw"
    "pinctrl_tigerlake"
    "intel_lpss"
    "intel_lpss_pci"
  ];

  boot.kernelPatches = [{ name = "ipts-hid"; patch = builtins.fetchurl "https://patch-diff.githubusercontent.com/raw/linux-surface/kernel/pull/132.diff"; }];

  nixpkgs.overlays = [
    (self: super: {
      iptsd = super.iptsd.overrideDerivation (attrs: {
        version = "66bd7c4d386c6bf4c77e008bb974ddcb8a52874e";
        src = pkgs.fetchFromGitHub {
          owner = "linux-surface";
          repo = "iptsd";
          rev = "66bd7c4d386c6bf4c77e008bb974ddcb8a52874e";
          sha256 = "uDt2V7FD8hafZQ22iQUjJACXV9/DiFAfLnpsEqmZTAI=";
        };
        nativeBuildInputs = attrs.nativeBuildInputs ++ [
          pkgs.cmake
        ];
        buildInputs = attrs.buildInputs ++ [
          pkgs.cli11
          pkgs.fmt_8.dev
          pkgs.spdlog.dev
          pkgs.microsoft_gsl
          pkgs.hidrd
          pkgs.SDL2.dev
          pkgs.cairomm.dev
        ];
        mesonFlags = [
          "-Dsample_config=false"
          "-Ddebug_tools=[]"
          "-Db_lto=false"
        ];
        postPatch = ''
          substituteInPlace etc/meson.build \
            --replace "install_dir: unitdir" "install_dir: datadir" \
            --replace "install_dir: rulesdir" "install_dir: datadir" \
        '';
      });
    })
  ];

  boot.extraModprobeConfig = ''
    options ithc hid=1
  '';

  systemd.services.iptsd = {
    description = "IPTSD";
    script = "${pkgs.iptsd}/bin/iptsd ''$(${pkgs.iptsd}/bin/iptsd-find-hidraw)";
    serviceConfig.Restart = "always";
    wantedBy = [
      "multi-user.target"
    ];
  };
}

