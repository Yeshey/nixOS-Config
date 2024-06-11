{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  c = config.myHome.colorScheme.theme.palette;
  cfg = config.myHome.homeApps.kitty;
in
{
  options.myHome.homeApps.kitty = with lib; {
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
          #font_family = "Fira Code";
          #bold_font = "Fira Code Bold";
          #font_size = "14.0";

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

          confirm_os_window_close = 0;

          # Color scheme
          #background_opacity = "0.8";

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
        };
    };
  };
}
