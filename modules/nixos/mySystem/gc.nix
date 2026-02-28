{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.gc;
in
{
  options.mySystem.gc = with lib; {
    # enable = mkEnableOption "gc";
  };

  config = { # always active

    # nix.gc = {
    #   automatic = lib.mkOverride 1010 true;
    #   options = lib.mkOverride 1010 "--delete-older-than 14d";
    #   dates = lib.mkOverride 1010 "weekly";
    # };

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.dates = "monthly";
      clean.extraArgs = "--keep-since 21d --keep 3";
      flake = "/home/yeshey/.setup";
    };

  };
}
