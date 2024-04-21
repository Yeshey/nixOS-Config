{ inputs, config, lib, pkgs, ... }:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.hyprland;
  c = config.myHome.colorScheme.theme.palette;
in
{
  imports = [ 
      # ./basic-binds.nix
      # ./hyprbars.nix # TODO, why doesnt this work..
      /*
       error: attribute 'hyprlandPlugins' missing

       at /nix/store/xvy6xsqgaqq1mb2hxkgy0v4d3c9yngqb-source/flake.nix:35:13:

           34|           hyprlandPlugins =
           35|             prev.hyprlandPlugins
             |             ^
           36|             // { */

  ];
  options.myHome.hyprland = with lib; {
    enable = mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {


    home.packages = with pkgs; [
      hyprpicker
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      systemd = {
        enable = true;
        # Same as default, but stop graphical-session too 
        extraCommands = lib.mkBefore [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };
/*
      settings = let
        active = "0xaa${lib.removePrefix "#" c.base00}";
        inactive = "0xaa${lib.removePrefix "#" c.base01}";
      in {
        general = {
          cursor_inactive_timeout = 4;
          gaps_in = 15;
          gaps_out = 20;
          border_size = 2;
          "col.active_border" = active;
          "col.inactive_border" = inactive;
        };
        group = {
          "col.border_active" = active;
          "col.border_inactive" = inactive;
          groupbar.font_size = 11;
        };
        binds = {
          movefocus_cycles_fullscreen = false;
        };
        input = {
          kb_layout = "br,us";
          touchpad.disable_while_typing = false;
        };
        dwindle = {
          split_width_multiplier = 1.35;
          pseudotile = true;
        };
        misc = {
          vfr = true;
          close_special_on_empty = true;
          focus_on_activate = true;
          # Unfullscreen when opening something
          new_window_takes_over_fullscreen = 2;
        };
        windowrulev2 = let
          sweethome3d-tooltips = "title:^(win[0-9])$,class:^(com-eteks-sweethome3d-SweetHome3DBootstrap)$";
          steam = "title:^()$,class:^(steam)$";
        in [
          "nofocus, ${sweethome3d-tooltips}"
          "stayfocused, ${steam}"
          "minsize 1 1, ${steam}"
        ];
        layerrule = [
          "animation fade,waybar"
          "blur,waybar"
          "ignorezero,waybar"
          "blur,notifications"
          "ignorezero,notifications"
          "blur,wofi"
          "ignorezero,wofi"
          "noanim,wallpaper"
        ];

        decoration = {
          active_opacity = 0.97;
          inactive_opacity = 0.77;
          fullscreen_opacity = 1.0;
          rounding = 7;
          blur = {
            enabled = true;
            size = 5;
            passes = 3;
            new_optimizations = true;
            ignore_opacity = true;
            popups = true;
          };
          drop_shadow = true;
          shadow_range = 12;
          shadow_offset = "3 3";
          "col.shadow" = "0x44000000";
          "col.shadow_inactive" = "0x66000000";
        };
        animations = {
          enabled = true;
          bezier = [
            "easein,0.11, 0, 0.5, 0"
            "easeout,0.5, 1, 0.89, 1"
            "easeinout,0.45, 0, 0.55, 1"
            "easeinback,0.36, 0, 0.66, -0.56"
            "easeoutback,0.34, 1.56, 0.64, 1"
            "easeinoutback,0.68, -0.6, 0.32, 1.6"
          ];

          animation = [
            "border,1,3,easeout"
            "workspaces,1,2,easeoutback,slide"
            "windowsIn,1,3,easeoutback,slide"
            "windowsOut,1,3,easeinback,slide"
            "windowsMove,1,3,easeoutback"
            "fadeIn,1,3,easeout"
            "fadeOut,1,3,easein"
            "fadeSwitch,1,3,easeinout"
            "fadeShadow,1,3,easeinout"
            "fadeDim,1,3,easeinout"
            "fadeLayersIn,1,3,easeoutback"
            "fadeLayersOut,1,3,easeinback"
            "layersIn,1,3,easeoutback,slide"
            "layersOut,1,3,easeinback,slide"
          ];
        };

        exec = ["${pkgs.swaybg}/bin/swaybg -i ${wallpaper} --mode fill"];

        bind = let
          # grimblast = lib.getExe pkgs.inputs.hyprwm-contrib.grimblast;
          tesseract = lib.getExe pkgs.tesseract;
          pactl = lib.getExe' pkgs.pulseaudio "pactl";
          # tly = lib.getExe pkgs.tly;
          gtk-play = lib.getExe' pkgs.libcanberra-gtk3 "canberra-gtk-play";
          notify-send = lib.getExe' pkgs.libnotify "notify-send";

          # terminal = config.home.sessionVariables.TERMINAL;
          defaultApp = type: "${lib.getExe' pkgs.gtk3 "gtk-launch"} $(${lib.getExe' pkgs.xdg-utils "xdg-mime"} query default ${type})";
          browser = defaultApp "x-scheme-handler/https";
          editor = defaultApp "text/plain";
        in
          [
            # Program bindings
            # "SUPER,Return,exec,${terminal}"
            "SUPER,e,exec,${editor}"
            "SUPER,v,exec,${editor}"
            "SUPER,b,exec,${browser}"
            # Brightness control (only works if the system has lightd)
            ",XF86MonBrightnessUp,exec,light -A 10"
            ",XF86MonBrightnessDown,exec,light -U 10"
            # Volume
            ",XF86AudioRaiseVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
            ",XF86AudioLowerVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
            ",XF86AudioMute,exec,${pactl} set-sink-mute @DEFAULT_SINK@ toggle"
            "SHIFT,XF86AudioMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
            ",XF86AudioMicMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
            # Screenshotting
            #",Print,exec,${grimblast} --notify --freeze copy output"
            #"SUPER,Print,exec,${grimblast} --notify --freeze copy area"
            # To OCR
            #"ALT,Print,exec,${grimblast} --freeze save area - | ${tesseract} - - | wl-copy && ${notify-send} -t 3000 'OCR result copied to buffer'"
            # Tally counter
            #"SUPER,z,exec,${notify-send} -t 1000 $(${tly} time) && ${tly} add && ${gtk-play} -i dialog-information" # Add new entry
            #"SUPERCONTROL,z,exec,${notify-send} -t 1000 $(${tly} time) && ${tly} undo && ${gtk-play} -i dialog-warning" # Undo last entry
            #"SUPERCONTROLSHIFT,z,exec,${tly} reset && ${gtk-play} -i complete" # Reset
            #"SUPERSHIFT,z,exec,${notify-send} -t 1000 $(${tly} time)" # Show current time
          ]
          ++ (
            let
              playerctl = lib.getExe' config.services.playerctld.package "playerctl";
              playerctld = lib.getExe' config.services.playerctld.package "playerctld";
            in
              lib.optionals config.services.playerctld.enable [
                # Media control
                ",XF86AudioNext,exec,${playerctl} next"
                ",XF86AudioPrev,exec,${playerctl} previous"
                ",XF86AudioPlay,exec,${playerctl} play-pause"
                ",XF86AudioStop,exec,${playerctl} stop"
                "ALT,XF86AudioNext,exec,${playerctld} shift"
                "ALT,XF86AudioPrev,exec,${playerctld} unshift"
                "ALT,XF86AudioPlay,exec,systemctl --user restart playerctld"
              ]
          )
          ++
          # Screen lock
          (
            let
              swaylock = lib.getExe config.programs.swaylock.package;
            in
              lib.optionals config.programs.swaylock.enable [
                ",XF86Launch5,exec,${swaylock} -S --grace 2"
                ",XF86Launch4,exec,${swaylock} -S --grace 2"
                "SUPER,backspace,exec,${swaylock} -S --grace 2"
              ]
          )
          ++
          # Notification manager
          (
            let
              makoctl = lib.getExe' config.services.mako.package "makoctl";
            in
              lib.optionals config.services.mako.enable ["SUPER,w,exec,${makoctl} dismiss"]
          )
          ++
          # Launcher
          (
            let
              wofi = lib.getExe config.programs.wofi.package;
            in
              lib.optionals config.programs.wofi.enable [
                "SUPER,x,exec,${wofi} -S drun -x 10 -y 10 -W 25% -H 60%"
                "SUPER,s,exec,specialisation $(specialisation | ${wofi} -S dmenu)"
                "SUPER,d,exec,${wofi} -S run"
              ]
              ++ (
                let
                  pass-wofi = lib.getExe (pkgs.pass-wofi.override {pass = config.programs.password-store.package;});
                in
                  lib.optionals config.programs.password-store.enable [
                    ",Scroll_Lock,exec,${pass-wofi}" # fn+k
                    ",XF86Calculator,exec,${pass-wofi}" # fn+f12
                    "SUPER,semicolon,exec,${pass-wofi}"
                    "SHIFT,Scroll_Lock,exec,${pass-wofi} fill" # fn+k
                    "SHIFT,XF86Calculator,exec,${pass-wofi} fill" # fn+f12
                    "SHIFTSUPER,semicolon,exec,${pass-wofi} fill"
                  ]
              )
          );
        monitor = let
          inherit (config.wayland.windowManager.hyprland.settings.general) gaps_in gaps_out;
          gap = gaps_out - gaps_in;
          inherit (config.programs.waybar.settings.primary) position height width;
          waybarSpace = {
            top =
              if (position == "top")
              then height + gap
              else 0;
            bottom =
              if (position == "bottom")
              then height + gap
              else 0;
            left =
              if (position == "left")
              then width + gap
              else 0;
            right =
              if (position == "right")
              then width + gap
              else 0;
          };
        in
          [
            ",addreserved,${toString waybarSpace.top},${toString waybarSpace.bottom},${toString waybarSpace.left},${toString waybarSpace.right}"
          ]
          ++ (map (
            m: "${m.name},${
              if m.enabled
              then "${toString m.width}x${toString m.height}@${toString m.refreshRate},${toString m.x}x${toString m.y},1"
              else "disable"
            }"
          ) (config.monitors));

        workspace = map (m: "${m.name},${m.workspace}") (
          lib.filter (m: m.enabled && m.workspace != null) config.monitors
        );
      };
      # This is order sensitive, so it has to come here.
      extraConfig = ''
        # Passthrough mode (e.g. for VNC)
        bind=SUPER,P,submap,passthrough
        submap=passthrough
        bind=SUPER,P,submap,reset
        submap=reset
      '';
      };

*/
    };

  };
}
