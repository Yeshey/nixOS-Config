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

    ./gnome/default.nix
    ./plasma/default.nix
    ./non-nixos.nix
    ./zsh/default.nix
    ./direnv.nix
    ./homeApps/default.nix
    ./hyprland/default.nix
    ./autoStartApps.nix
    ./onedriver.nix
    ./onedriver2.nix
    ./agenix/default.nix
    ./ssh/default.nix
    ./stylix.nix
    ./xdgPersonalFilesOrganization.nix
    ./impermanence.nix
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
    nix.gc = {
      automatic = lib.mkOverride 1010 true;
      options = lib.mkOverride 1010 "--delete-older-than 14d";
      frequency = lib.mkOverride 1010 "weekly";
    };

    ### MY SCRIPTS ###
    home.packages = let 
      upgarde-new = pkgs.writeShellScriptBin "upgarde-new" (builtins.readFile ./myScripts/upgrade.sh);
      upgrade-with-remote-off-new = pkgs.writeShellScriptBin "upgrade-with-remote-off-new" (builtins.readFile ./myScripts/upgrade-with-remote-off.sh);
      update-with-remote-off-new = pkgs.writeShellScriptBin "update-with-remote-off-new" (builtins.readFile ./myScripts/update-with-remote-off.sh);
    in with pkgs; [
      upgarde-new
      upgrade-with-remote-off-new
      update-with-remote-off-new
    ];
  };
}
