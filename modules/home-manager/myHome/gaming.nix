{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.gaming;
in
{
  options.myHome.gaming = with lib; {
    enable = mkEnableOption "gaming";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
        # Games
        osu-lazer
        lutris
        # tetrio-desktop # runs horribly, better on the web
        prismlauncher # polymc # prismlauncher # for Minecraft
        heroic
        minetest
        the-powder-toy
        mindustry
    ];
  };
}