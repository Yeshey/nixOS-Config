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
    mobile = {
      enable = lib.mkEnableOption "Activates Phosh desktop environment for mobile devices";
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
        displayManager.gdm = {
          enable = lib.mkOverride 1010 true;
          # autoSuspend = false;
          settings = {
            greeter.IncludeAll = true;
          };
        };
        desktopManager = {
          # Enable GNOME only if Phosh is not enabled
          gnome = lib.mkIf (!cfg.mobile.enable) {
            enable = true;
          };

          # Enable Phosh only if `mobile` is enabled
          phosh = lib.mkIf cfg.mobile.enable {
            enable = true;
            package = pkgs.phosh;
            user = "${config.mySystem.user}";  # User running Phosh
            group = "users";  # Group running Phosh
            #phocConfig = ''  # Add any custom Phoc compositor configuration if needed
            #'';
          };
        };
      };
      udev.packages = [ pkgs.gnome-settings-daemon ];
    };

    security.rtkit.enable = true;
  };
}
