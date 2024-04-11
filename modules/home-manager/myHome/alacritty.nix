{ config, lib, pkgs, ... }:

let
  c = config.myHome.colorScheme.palette;
  cfg = config.myHome.alacritty;
  fontName = config.myHome.gnome.font.name;
  fontSize = config.myHome.gnome.font.size;
in {
  options.myHome.alacritty = with lib; {
    enable = mkEnableOption "alacritty";
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
        window = {
          padding = { x = 6; y = 6; };
          opacity = 0.90;
        };
        cursor = {
          thickness = 0.1;
        };
        font = {
          normal = {
            family = fontName;
            style = "Regular";
          };
          bold = {
            family = fontName;
            style = "Bold";
          };
          italic = {
            family = fontName;
            style = "Italic";
          };
          bold_italic = {
            family = fontName;
            style = "Bold Italic";
          };
          size = fontSize;
        };
        colors = {
            primary = {
                background = "#${c.base00}"; #1B2B34
                foreground = "#${c.base05}"; #CDD3DE
            };
            cursor = {
                text = "#${c.base00}"; #1B2B34
                cursor = "#${c.base05}"; #CDD3DE
            };
        };
      };
    };
  };
}
