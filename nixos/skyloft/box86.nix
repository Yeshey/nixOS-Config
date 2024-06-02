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

    environment.systemPackages = [
      #box86Pkgs.box86
      pkgs.mybox86
    ];

  };
}
