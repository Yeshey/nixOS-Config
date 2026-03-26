{
  inputs,
  ...
}:
{
  flake.modules.nixos.gnome-base = 
    { pkgs, lib, ... }: 
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.gnome-base
      ];
      imports = with inputs.self.modules.nixos; [
        gnome-minimal
      ];

      i18n.inputMethod = {
        enable = true;
        type = "ibus";
      };

      environment.systemPackages = with pkgs; [
        gnome-tweaks
        ffmpeg-headless
        ffmpegthumbnailer
        gdk-pixbuf
        libheif.bin
        libheif.out
        libavif
        libjxl
        webp-pixbuf-loader
      ];

      environment.gnome.excludePackages = with pkgs; [
        epiphany
        gnome-connections
        gnome-music
      ];

      environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
        lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-plugins-base
        ]);
    };

  flake.modules.homeManager.gnome-base = 
    { lib, ... }: 
    {
      imports = with inputs.self.modules.homeManager; [
        gnome-minimal
      ];

      dconf.settings = {
        "org/gnome/system/location" = { # enables location in gnome
          enabled = true;
        };

        "org/gnome/desktop/peripherals/touchpad" = {
          click-method = "areas";
          tap-to-click = true;
        };

        "org/gnome/desktop/privacy" = {
          remove-old-temp-files = true;
          remove-old-trash-files = true;
        };

        "org/gnome/desktop/sound" = {
          allow-volume-above-100-percent = true;
          input-feedback-sounds = true;
        };

        "org/gnome/desktop/wm/keybindings" = {
          show-desktop = [ "<Super>d" ];
          switch-windows = [ "<Alt>Tab" ];
          switch-windows-backward = [ "<Shift><Alt>Tab" ];
          switch-applications = [ ];
          switch-applications-backward = [ ]; # Optional: also disable reverse app switching
        };

        "org/gnome/shell/window-switcher" = {
          current-workspace-only = false;
        };

        "org/gnome/desktop/input-sources" = with lib.hm.gvariant; {
          show-all-sources = false;
          sources = [
            (mkTuple [
              "xkb"
              "pt"
            ])
            (mkTuple [
              "xkb"
              "br"
            ])
            (mkTuple [
              "xkb"
              "us"
            ])
          ];
          xkb-options = [ "terminate:ctrl_alt_bksp" ];
        };

        "org/gnome/desktop/interface" = {
          clock-show-seconds = true;
          clock-show-weekday = true;
          show-battery-percentage = true;
        };

        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
          resize-with-right-button = true;
        };

        "org/gnome/nautilus/preferences" = {
          show-create-link = true;
          show-delete-permanently = true;
        };

        "org/gnome/shell/extensions/appindicator" = {
          tray-pos = "left";
        };

        "org/gnome/shell/extensions/system-monitor" = {
          show-download = false;
          show-upload = false;
        };
      };
    };
}