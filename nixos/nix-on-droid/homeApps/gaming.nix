{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.gaming;
in
{
  options.myHome.homeApps.gaming = with lib; {
    enable = mkEnableOption "gaming";
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {
    home.packages = with pkgs; [
      /*
      # Games
      unstable.osu-lazer
      # tetrio-desktop # runs horribly, better on the web
      prismlauncher # polymc # prismlauncher # for Minecraft
      heroic
      minetest
      the-powder-toy
      */
    ];

  };
}
