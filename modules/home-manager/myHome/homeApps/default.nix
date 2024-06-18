{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps;
in
{
  imports = [
    ./general.nix
    ./vscodium
    ./discord.nix
    ./kitty.nix
    ./alacritty.nix
    ./gaming.nix
    ./firefox.nix
    ./libreoffice.nix
    ./devops.nix
    ./cli
    ./webApps.nix
  ];

  options.myHome.homeApps = {
    enable = lib.mkEnableOption "homeApps";
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {
    myHome.homeApps.general.enable = lib.mkOverride 1010 true;
    myHome.homeApps.vscodium.enable = lib.mkOverride 1010 true;
    myHome.homeApps.discord.enable = lib.mkOverride 1010 true;
    myHome.homeApps.kitty.enable = lib.mkOverride 1010 false;
    myHome.homeApps.alacritty.enable = lib.mkOverride 1010 false;
    myHome.homeApps.gaming.enable = lib.mkOverride 1010 true;
    myHome.homeApps.firefox.enable = lib.mkOverride 1010 true;
    myHome.homeApps.libreoffice.enable = lib.mkOverride 1010 true;
    myHome.homeApps.devops.enable = lib.mkOverride 1010 true;
    myHome.homeApps.cli.enable = lib.mkOverride 1010 true;
    myHome.homeApps.webApps.enable = lib.mkOverride 1010 true;
  };
}
