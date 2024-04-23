{ inputs, config, lib, pkgs, ... }:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.hyprland;
  c = config.myHome.colorScheme.theme.palette;
in
{
  config = lib.mkIf cfg.enable {

    wayland.windowManager.hyprland.settings = 
      let
        screenshotarea = "hyprctl keyword animation 'fadeOut,0,0,default'; grimblast --notify copysave area; hyprctl keyword animation 'fadeOut,1,4,default'";
        workspaces = builtins.concatLists (builtins.genList (
            x: let
              ws = let
                c = (x + 1) / 10;
              in
                builtins.toString (x + 1 - (c * 10));
            in [
              "$mod, ${ws}, workspace, ${toString (x + 1)}"
              "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
            ]
          )
          10);
        pointer = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 16;
          gtk.enable = true;
          x11.enable = true;
        };
      in 
      {

      # ============================ RULES ============================

      # layer rules
      layerrule = let
        toRegex = list: let
          elements = lib.concatStringsSep "|" list;
        in "^(${elements})$";

        ignorealpha = [
          # ags
          "calendar"
          "notifications"
          "osd"
          "system-menu"

          "anyrun"
        ];

        layers = ignorealpha ++ ["bar" "gtk-layer-shell"];
      in [
        "blur, ${toRegex layers}"
        "xray 1, ${toRegex ["bar" "gtk-layer-shell"]}"
        "ignorealpha 0.2, ${toRegex ["bar" "gtk-layer-shell"]}"
        "ignorealpha 0.5, ${toRegex (ignorealpha ++ ["music"])}"
      ];

      # window rules
      windowrulev2 = [
        # telegram media viewer
        "float, title:^(Media viewer)$"

        # allow tearing in games
        "immediate, class:^(osu\!|cs2)$"

        # make Firefox PiP window floating and sticky
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"

        # throw sharing indicators away
        "workspace special silent, title:^(Firefox — Sharing Indicator)$"
        "workspace special silent, title:^(.*is sharing (your screen|a window)\.)$"

        # start spotify in ws9
        "workspace 9 silent, title:^(Spotify( Premium)?)$"

        # idle inhibit while watching videos
        "idleinhibit focus, class:^(mpv|.+exe|celluloid)$"
        "idleinhibit focus, class:^(firefox)$, title:^(.*YouTube.*)$"
        "idleinhibit fullscreen, class:^(firefox)$"

        "dimaround, class:^(gcr-prompter)$"
        "dimaround, class:^(xdg-desktop-portal-gtk)$"
        "dimaround, class:^(polkit-gnome-authentication-agent-1)$"

        # fix xwayland apps
        "rounding 0, xwayland:1"
        "center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$"
        "size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$"
      ];

      # ============================ SETTINGS ============================

      "$mod" = "SUPER";
      "$menu" = "wofi --show drun";
      "$filemanager" = "nautilus";
      env = [
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
      ];

      exec-once = [
        # set cursor for HL itself
        "hyprctl setcursor ${pointer.name} ${toString pointer.size}"
        "systemctl --user start clight"
        "hyprlock"
        "waybar"
        "wlsunset" # for night light, idk how to configure :(
        "nm-applet --indicator & disown" # for internet
        "copyq --start-server" # for clipboard
        "wl-paste --watch cliphist store" #Stores only text data
      ];

      general = {
        gaps_in = 5;
        gaps_out = 5;
        border_size = 1;
        #"col.active_border" = "rgba(88888888)";
        #"col.inactive_border" = "rgba(00000088)";

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
        # "col.shadow" = "rgba(00000055)";
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

        #"col.border_active" = "rgba(${c.base00}88);"; # primary
        #"col.border_inactive" = "rgba(${c.base01}88)"; # primary variant
      };

      input = {
        # kb_layout = "ro";
        kb_layout = "pt,br,us";
        kb_options = "grp:alt_space_toggle ";

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
        # disable_autoreload = true;

        force_default_wallpaper = 0;

        # disable dragging animation
        # animate_mouse_windowdragging = false;

        # enable variable refresh rate (effective depending on hardware)
        # vrr = 1;

        # we do, in fact, want direct scanout
        # no_direct_scanout = false;
      };

      # touchpad gestures
      gestures = {
        workspace_swipe = true;
        workspace_swipe_forever = true;
      };

      xwayland.force_zero_scaling = true;

      debug.disable_logs = false;

      # ============================ BINDS ============================

      # mouse movements
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];

      # binds
      bind = let
        monocle = "dwindle:no_gaps_when_only";
      in
        [
          "$mod, T, exec, kitty"
          "$mod, SPACE, exec, $menu"
          "$mod, E, exec, $filemanager"

          # compositor commands
          "$mod SHIFT, E, exec, pkill Hyprland"
          "$mod, Q, killactive,"
          "$mod, F, fullscreen,"
          "$mod, G, togglegroup,"
          "$mod SHIFT, N, changegroupactive, f"
          "$mod SHIFT, P, changegroupactive, b"
          "$mod, R, togglesplit,"
          "$mod, S, togglefloating,"
          "$mod, P, pseudo,"
          "$mod ALT, ,resizeactive,"

          # alt tab
          "ALT, Tab, cyclenext,"
          "ALT, Tab, bringactivetotop,"
          "ALT SHIFT, Tab, cyclenext, prev"

          "$mod, M, exec, hyprctl keyword ${monocle} $(($(hyprctl getoption ${monocle} -j | jaq -r '.int') ^ 1))"
          "$mod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

          # utility
          # terminal
          "$mod, Return, exec, run-as-service foot"
          # logout menu
          "$mod, Escape, exec, wlogout -p layer-shell"
          # lock screen
          "$mod, L, exec, loginctl lock-session"
          # select area to perform OCR on
          "$mod, O, exec, run-as-service wl-ocr"

          # move focus
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"

          # screenshot
          # stop animations while screenshotting; makes black border go away
          ", Print, exec, ${screenshotarea}"
          "$mod SHIFT, R, exec, ${screenshotarea}"

          "CTRL, Print, exec, grimblast --notify --cursor copysave output"
          "$mod SHIFT CTRL, R, exec, grimblast --notify --cursor copysave output"

          "ALT, Print, exec, grimblast --notify --cursor copysave screen"
          "$mod SHIFT ALT, R, exec, grimblast --notify --cursor copysave screen"

          # special workspace
          "$mod SHIFT, grave, movetoworkspace, special"
          "$mod, grave, togglespecialworkspace, eDP-1"

          # cycle workspaces
          "$mod, bracketleft, workspace, m-1"
          "$mod, bracketright, workspace, m+1"

          # cycle monitors
          "$mod SHIFT, bracketleft, focusmonitor, l"
          "$mod SHIFT, bracketright, focusmonitor, r"

          # send focused workspace to left/right monitors
          "$mod SHIFT ALT, bracketleft, movecurrentworkspacetomonitor, l"
          "$mod SHIFT ALT, bracketright, movecurrentworkspacetomonitor, r"
        ]
        ++ workspaces;

      bindr = [
        # launcher
        "$mod, SUPER_L, exec, pkill .anyrun-wrapped || run-as-service anyrun"
      ];

      bindl = [
        # media controls
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"

        # volume
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      bindle = [
        # volume
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%-"

        # backlight
        ", XF86MonBrightnessUp, exec, brillo -q -u 300000 -A 5"
        ", XF86MonBrightnessDown, exec, brillo -q -u 300000 -U 5"
      ];

    };

  };
}
