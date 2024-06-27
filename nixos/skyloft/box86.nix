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
in
{
  imports = [
    
  ];
  
  options.mySystem.box86 = {
    enable = mkEnableOption "box86";
  };

  config = lib.mkIf cfg.enable {

    # boot.binfmt.emulatedSystems = [ "armv7l-linux" "x86_64-linux" ];
    # boot.binfmt.registrations.armv7l-linux.preserveArgvZero = true;

    #nix.settings.extra-platforms = "armv7l-linux";

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

      #pkgs.steam pkgs.steam-run
    ];

  };
}
