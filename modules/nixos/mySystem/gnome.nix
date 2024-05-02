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

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ firefox ];
      gnome.excludePackages = with pkgs.gnome; [
        cheese # webcam tool
        gedit # text editor
        epiphany # web browser
        geary # email reader
        evince # document viewer
        totem # video player
        pkgs.gnome-connections
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
        displayManager.gdm = {
          enable = true;
          autoSuspend = false;
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
