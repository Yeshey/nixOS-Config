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

  config = lib.mkIf cfg.enable {
    myHome.homeApps.general.enable = lib.mkDefault true;
    myHome.homeApps.vscodium.enable = lib.mkDefault true;
    myHome.homeApps.discord.enable = lib.mkDefault true;
    myHome.homeApps.kitty.enable = lib.mkDefault false;
    myHome.homeApps.alacritty.enable = lib.mkDefault false;
    myHome.homeApps.gaming.enable = lib.mkDefault true;
    myHome.homeApps.firefox.enable = lib.mkDefault true;
    myHome.homeApps.libreoffice.enable = lib.mkDefault true;
    myHome.homeApps.devops.enable = lib.mkDefault true;
    myHome.homeApps.cli.enable = lib.mkDefault true;
    myHome.homeApps.webApps.enable = lib.mkDefault true;
  };
}
