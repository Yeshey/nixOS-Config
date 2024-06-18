{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
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
    nvidia = mkEnableOption "nvidia";
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

  };
}
