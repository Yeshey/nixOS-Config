{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.cli;
in
{
  imports = [
    ./tmux.nix
    ./general.nix
    ./git.nix
    ./neovim.nix
  ];

  options.myHome.homeApps.cli = {
    enable = lib.mkEnableOption "cli";
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && config.myHome.homeApps.cli.enable && cfg.enable) {
    myHome.homeApps.cli.git.enable = lib.mkOverride 1010 true;
    myHome.homeApps.cli.general.enable = lib.mkOverride 1010 true;
    myHome.homeApps.cli.tmux.enable = lib.mkOverride 1010 true;
  };
}
