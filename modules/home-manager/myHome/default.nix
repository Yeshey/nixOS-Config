{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = config.myHome;
in
{
  imports = [
    ./safe-rm.nix # always active
    ./gc.nix # always active
    ./myScripts.nix

    ./gnome/default.nix
    ./plasma/default.nix
    ./non-nixos.nix
    ./zsh/default.nix
    ./direnv.nix
    ./homeApps/default.nix
    ./hyprland/default.nix
    ./autoStartApps.nix
    ./agenix/default.nix
    ./ssh/default.nix
    ./stylix.nix
    ./xdgPersonalFilesOrganization.nix
    ./impermanence.nix
    ./autosshReverseProxyHome.nix
    ./warnElections/default.nix
    ./desktopItems.nix
    ./nh.nix
  ];
  options.myHome = with lib; {
    enable = mkEnableOption "myHome";
    dataStoragePath = mkOption {
      type = types.str;
      description = "Storage drive or path to put everything. needs to be set if not set in mySystem module.";
      default = "${osConfig.mySystem.dataStoragePath}";
    };
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
  };
}
