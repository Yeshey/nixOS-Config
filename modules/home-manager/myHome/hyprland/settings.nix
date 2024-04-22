{ inputs, config, lib, pkgs, ... }:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.hyprland;
  c = config.myHome.colorScheme.theme.palette;

  pointer = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
    gtk.enable = true;
    x11.enable = true;
  };
in
{

  config = lib.mkIf cfg.enable {

    wayland.windowManager.hyprland.settings = {
      "$mod" = "SUPER";
      "$menu" = "wofi --show drun";
      env = [
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "WLR_NO_HARDWARE_CURSORS,1"
      ];

      exec-once = [
        # set cursor for HL itself
        "hyprctl setcursor ${pointer.name} ${toString pointer.size}"
        "systemctl --user start clight"
        "hyprlock"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 5;
        border_size = 1;
        "col.active_border" = "rgba(88888888)";
        "col.inactive_border" = "rgba(00000088)";

        allow_tearing = true;
        resize_on_border = true;
      };

      decoration = {
        rounding = 16;
        blur = {
          enabled = true;
          brightness = 1.0;
          contrast = 1.0;
          noise = 0.02;

          passes = 3;
          size = 10;
        };

        drop_shadow = true;
        shadow_ignore_window = true;
        shadow_offset = "0 2";
        shadow_range = 20;
        shadow_render_power = 3;
        "col.shadow" = "rgba(00000055)";
      };

      animations = {
        enabled = true;
        animation = [
          "border, 1, 2, default"
          "fade, 1, 4, default"
          "windows, 1, 3, default, popin 80%"
          "workspaces, 1, 2, default, slide"
        ];
      };

      group = {
        groupbar = {
          font_size = 16;
          gradients = false;
        };

        "col.border_active" = "rgba(${c.base00}88);"; # primary
        "col.border_inactive" = "rgba(${c.base01}88)"; # primary variant
      };

      input = {
        kb_layout = "ro";

        # focus change on cursor move
        follow_mouse = 1;
        accel_profile = "flat";
        touchpad.scroll_factor = 0.1;
      };

      dwindle = {
        # keep floating dimentions while tiling
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        # disable auto polling for config file changes
        disable_autoreload = true;

        force_default_wallpaper = 0;

        # disable dragging animation
        animate_mouse_windowdragging = false;

        # enable variable refresh rate (effective depending on hardware)
        vrr = 1;

        # we do, in fact, want direct scanout
        no_direct_scanout = false;
      };

      # touchpad gestures
      gestures = {
        workspace_swipe = true;
        workspace_swipe_forever = true;
      };

      xwayland.force_zero_scaling = true;

      debug.disable_logs = false;
    };

    wayland.windowManager.hyprland.extraConfig = ''
      plugin {
        csgo-vulkan-fix {
          res_w = 1280
          res_h = 800
          class = cs2
        }
      }
    '';
  };
}
