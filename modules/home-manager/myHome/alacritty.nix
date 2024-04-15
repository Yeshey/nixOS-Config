{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  c = config.myHome.colorScheme.palette;
  cfg = config.myHome.alacritty;
  fontName = config.myHome.gnome.font.name;
  fontSize = config.myHome.gnome.font.size;
in
{
  options.myHome.alacritty = with lib; {
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
          opacity = 0.9;
        };
        colors =
          with c;
          lib.mkIf (config.myHome.colorScheme != null) {
            bright = {
              black = "0x${base00}";
              blue = "0x${base0D}";
              cyan = "0x${base0C}";
              green = "0x${base0B}";
              magenta = "0x${base0E}";
              red = "0x${base08}";
              white = "0x${base06}";
              yellow = "0x${base09}";
            };
            cursor = {
              cursor = "0x${base06}";
              text = "0x${base06}";
            };
            normal = {
              black = "0x${base00}";
              blue = "0x${base0D}";
              cyan = "0x${base0C}";
              green = "0x${base0B}";
              magenta = "0x${base0E}";
              red = "0x${base08}";
              white = "0x${base06}";
              yellow = "0x${base0A}";
            };
            primary = {
              background = "0x${base00}";
              foreground = "0x${base06}";
            };
          };
      };
    };
  };
}