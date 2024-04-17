{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  c = config.myHome.colorScheme.theme.palette;
  cfg = config.myHome.kitty;
in
{
  options.myHome.kitty = with lib; {
    enable = mkEnableOption "kitty";
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      package = pkgs.kitty;
      shellIntegration = {
        enableBashIntegration = true;
        enableZshIntegration = true;
      };
      # theme = "Space Gray Eighties";
      settings =
        {
          # Fonts
          font_family = "Fira Code";
          bold_font = "Fira Code Bold";
          font_size = "14.0";

          # Cursor customization
          cursor_blink_interval = 0;
          cursor_shape = "block";

          # Scrollback
          scrollback_lines = 2000;
          wheel_scroll_multiplier = "0.0";

          # Mouse
          copy_on_select = false;

          # Performance tuning
          repaint_delay = 10;
          input_delay = 3;
          sync_to_monitor = true;

          # Terminal bell
          enable_audio_bell = false;

          # Window layout
          remember_window_size = true;
          enabled_layouts = "*";

          # Color scheme
          background_opacity = "0.8";

          wayland_titlebar_color = "background";
          #linux_display_server = "x11";

          # Keyboard shortcuts
          "map.kitty_mod" = "ctrl+shift";
          "map.kitty_mod+e" = "kitten hints";
          "map.kitty_mod+p+f" = "kitten hints --type path --program -";
          "map.kitty_mod+p+l" = "kitten hints --type line --program -";
          "map.kitty_mod+p+w" = "kitten hints --type word --program -";
          "map.kitty_mod+p+h" = "kitten hints --type hash --program -";
          "map.kitty_mod+f11" = "toggle_fullscreen";
          "map.kitty_mod+u" = "kitten unicode_input";
          "map.kitty_mod+f2" = "edit_config_file";
          "map.kitty_mod+escape" = "kitty_shell window";
          "map.kitty_mod+a+m" = "set_background_opacity +0.1";
          "map.kitty_mod+a+l" = "set_background_opacity -0.1";
          "map.kitty_mod+a+1" = "set_background_opacity 1";
          "map.kitty_mod+a+d" = "set_background_opacity default";
          "map.kitty_mod+delete" = "clear_terminal reset active";
        }
        // (
          if config.myHome.colorScheme != null then
            {
              foreground = "#${c.base05}"; # "#d3c6aa";
              background = "#${c.base00}"; # "#272e33";
              selection_foreground = "#${c.base05}"; # "#d3c6aa";
              selection_background = "#${c.base02}"; # "#414b50";

              color0 = "#${c.base00}"; # "#272e33";
              color1 = "#${c.base0E}"; # "#e67e80";
              color2 = "#${c.base0B}"; # "#83c092";
              color3 = "#${c.base0A}"; # "#dbbc7f";
              color4 = "#${c.base08}"; # "#7fbbb3";
              color5 = "#${c.base09}"; # "#d699b6";
              color6 = "#${c.base0D}"; # "#a7c080";
              color7 = "#${c.base06}"; # "#e4e1cd";
              color8 = "#${c.base02}"; # "#414b50";
              color9 = "#${c.base0E}"; # "#e67e80";
              color10 = "#${c.base0D}"; # "#a7c080";
              color11 = "#${c.base0A}"; # "#dbbc7f";
              color12 = "#${c.base04}"; # "#9da9a0";
              color13 = "#${c.base05}"; # "#d3c6aa";
              color14 = "#${c.base0B}"; # "#83c092";
              color15 = "#${c.base07}"; # "#fdf6e3";
            }
          else
            { }
        );
    };
  };
}