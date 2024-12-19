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
    defaultSession = lib.mkOption {
      type = lib.types.str;
      default = "gnome";
      example = "gnome-xorg";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    environment = {
      systemPackages = with pkgs; [ firefox gnome-tweaks ];
      gnome.excludePackages = with pkgs; [
        cheese # webcam tool
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

    services = {
      xserver = {
        enable = true;
        # layout = "pt";
        displayManager = {
          defaultSession = lib.mkOverride 1010 cfg.defaultSession;
          gdm = {
            enable = lib.mkOverride 1010 true;
            # autoSuspend = false;
            settings = {
              greeter.IncludeAll = true;
            };
          };
        };
        desktopManager.gnome.enable = true;
      };
      udev.packages = [ pkgs.gnome-settings-daemon ];
    };

    security.rtkit.enable = true;
  };
}
