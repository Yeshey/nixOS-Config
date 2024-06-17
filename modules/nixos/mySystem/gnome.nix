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
      systemPackages = with pkgs; [ firefox gnome.gnome-tweaks ];
      gnome.excludePackages = with pkgs; [
        gnome.cheese # webcam tool
        gedit # text editor
        epiphany # web browser
        gnome.geary # email reader
        #evince # document viewer
        gnome.totem # video player
        gnome-connections
        gnome.gnome-contacts
        # gnome-maps
        gnome.gnome-music
        gnome.gnome-weather
      ];
    };

    services = {
      xserver = {
        enable = true;
        # layout = "pt";
        displayManager.gdm = {
          enable = true;
          # autoSuspend = false;
          settings = {
            greeter.IncludeAll = true;
          };
        };
        desktopManager.gnome.enable = true;
      };
      udev.packages = [ pkgs.gnome.gnome-settings-daemon ];
    };

    security.rtkit.enable = true;
  };
}
