{
  config,
  lib,
  pkgs,
  outputs,
  ...
}:

let
  cfg = config.mySystem.gnome;
in
{
  options.mySystem.gnome = {
    enable = lib.mkEnableOption "gnome";
    mobile = {
      enable = lib.mkEnableOption "Activates GNOME mobile desktop environment";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) (lib.mkMerge [
    {
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
          displayManager.gdm = {
            enable = lib.mkOverride 1010 true;
            settings.greeter.IncludeAll = true;
          };
          desktopManager.gnome.enable = true;
        };
        udev.packages = [ pkgs.gnome-settings-daemon ];
      };

      security.rtkit.enable = true;
    }
    (lib.mkIf cfg.mobile.enable {
      # Mobile-specific configuration
      nixpkgs.overlays = [
        # Only add mobile overlay when mobile enabled
        outputs.overlays.gnome-mobile
      ];

      # Mobile-specific packages
      environment.systemPackages = with pkgs; [
        #squeekboard
      ];
    })
  ]);
}