{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.gnome;
in
{
  options.mySystem.gnome = {
    enable = lib.mkEnableOption "gnome";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    environment = {
      systemPackages = with pkgs; [ firefox ];
      gnome.excludePackages = with pkgs; [
        gedit # text editor
        epiphany # web browser
        geary # email reader
        #evince # document viewer
        totem # video player
        gnome-connections
        gnome-contacts
        # gnome-maps
        gnome-music
        gnome-weather
      ];
    };

    # for audio and video properties in nautilus interface https://github.com/NixOS/nixpkgs/issues/53631
    environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      pkgs.gst_all_1.gst-plugins-ugly
      pkgs.gst_all_1.gst-plugins-base
    ];

    services = {
      xserver = {
        enable = true;
        # layout = "pt";
        displayManager.gdm = {
          enable = lib.mkOverride 1010 true;
          # autoSuspend = false;
          settings = {
            greeter.IncludeAll = true;
          };
        };
        desktopManager = {
          gnome.enable = true;
        };
      };
      udev.packages = [ pkgs.gnome-settings-daemon ];
    };

    security.rtkit.enable = true;
  };
}
