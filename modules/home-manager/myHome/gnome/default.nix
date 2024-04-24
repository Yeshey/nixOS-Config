{
  config,
  lib,
  pkgs,
  ...
}:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.gnome;
in
{
  imports = [ ./dconf.nix ];
  options.myHome.gnome = with lib; {
    enable = mkEnableOption "gnome";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # For gnome
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.burn-my-windows
      gnomeExtensions.hibernate-status-button
      gnomeExtensions.tray-icons-reloaded
    ];
    dconf.settings = {
      "org/gnome/desktop/background" = lib.mkIf (wallpaper != null) {
        picture-uri = "file://${wallpaper}";
        picture-uri-dark = "file://${wallpaper}";
      };
    };
  };
}
