{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  c = config.myHome.colorScheme.theme.palette;
  cfg = config.myHome.homeApps.alacritty;
in
{
  options.myHome.homeApps.alacritty = with lib; {
    enable = mkEnableOption "alacritty";
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          padding = {
            x = 6;
            y = 6;
          };
          #opacity = 0.9;
        };
      };
    };
  };
}
