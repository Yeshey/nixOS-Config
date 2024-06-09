{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.mySystem.box86;

  # the box86 package commit https://github.com/NixOS/nixpkgs/pull/174113
  inherit (pkgs.stdenv.hostPlatform) system;
  box86Pkgs = import (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/45f7e1cb53c0b5026a3db49c85ecc6a10f57c4ad.tar.gz";
        sha256 = "sha256:1q320nvidbgawypn2jr4v6h6kkd1slc9qwp2p9yc5sswhys7j64y";
    }) {
    inherit system;
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true;
  };
in
{
  imports = [
    
  ];
  
  options.mySystem.box86 = {
    enable = mkEnableOption "box86";
  };

  config = lib.mkIf cfg.enable {

    boot.binfmt.emulatedSystems = [ "armv7l-linux" ];
    boot.binfmt.registrations.armv7l-linux.preserveArgvZero = true;

  containers.gaming = {
    autoStart = true;
    path = ./boxcontainer;
    /*config = { config, pkgs, ... }: {
      imports = [
        # Import the container configuration from the flake
        (import (fetchTarball {
          url = "/home/yeshey/PersonalFiles/tmp/container/flake.nix";
          inputs = { inherit pkgs lib; };
        }) { inherit pkgs lib; }).nixosConfigurations.container;
      ];
    };*/
  };

/*
    containers.gaming.autoStart = true;
    containers.gaming =
      { config =
          { config, pkgs, ... }:
          { services.postgresql.enable = true;
          services.postgresql.package = pkgs.postgresql_14;
          };
      }; */

    # https://github.com/NixOS/nixpkgs/pull/174113
    # Jogos que funcionam: https://box86.org/app/

    environment.systemPackages = [
      #box86Pkgs.box86
      pkgs.mybox86
      pkgs.box64
    ];

  };
}
