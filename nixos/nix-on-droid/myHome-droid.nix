{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome;
in
{
  imports = [

  ];
  options.myHome = with lib; {
    enable = mkEnableOption "myHome";
    dataStoragePath = mkOption {
      type = types.str;
      description = "Storage drive or path to put everything. needs to be set if not set in mySystem module.";
      default = "/data/data/com.termux.nix/files/home";
    };
    user = mkOption {
      type = types.str;
      default = "nix-on-droid";
    };
  };
  config = {
    home = rec {
      username = lib.mkOverride 1010 cfg.user; # TODO username
      homeDirectory = lib.mkOverride 1010 "/home/${username}";
      stateVersion = lib.mkOverride 1010 "22.11";
    };
    nix.gc = {
      automatic = lib.mkOverride 1010 true;
      options = lib.mkOverride 1010 "--delete-older-than 14d";
      frequency = lib.mkOverride 1010 "weekly";
    };
  };
}
