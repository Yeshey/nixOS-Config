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
    ./gnome/default.nix
    ./plasma/default.nix
    ./non-nixos.nix
    ./zsh/default.nix
    ./direnv.nix
    ./homeApps/default.nix
    ./hyprland/default.nix
    ./autoStartApps.nix
    ./onedriver.nix
    ./agenix/default.nix
    ./ssh/default.nix
    ./stylix.nix
    ./xdgPersonalFilesOrganization.nix
  ];
  options.myHome = with lib; {
    enable = lib.mkEnableOption "myHome";
    user = mkOption {
      type = types.str;
      default = "yeshey";
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
