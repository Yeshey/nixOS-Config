{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.gc;
in
{
  options.myHome.gc = with lib; {
    #enable = mkEnableOption "gc";
  };

  config = { # always active

    # nix.gc = {
    #   automatic = lib.mkOverride 1010 true;
    #   options = lib.mkOverride 1010 "--delete-older-than 14d";
    #   frequency = lib.mkOverride 1010 "weekly";
    # };

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 2d --keep 3";
      flake = "/home/yeshey/.setup";
    };

  };
}
