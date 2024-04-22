{ inputs, config, lib, pkgs, ... }:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.hyprland;
  c = config.myHome.colorScheme.theme.palette;
in
{
  imports = [
    ./dunst
    ./hypr
    ./rofi
    ./waybar
  ];
  options.myHome.hyprland = with lib; {
    enable = mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {
    
  };
}