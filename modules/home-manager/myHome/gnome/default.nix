{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = config.myHome.gnome;
in
{
  imports = [ ./dconf.nix ];
  options.myHome.gnome = with lib; {
    enable = mkOption {
      type = types.bool;
      default = (osConfig.mySystem.gnome.enable or false) || (osConfig.services.xserver.desktopManager.gnome.enable or false);
      description = "personal gnome configuration";
    };
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {
    home.packages = with pkgs; [
      gnome-tweaks
      # For gnome
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.burn-my-windows
      gnomeExtensions.hibernate-status-button
      gnomeExtensions.tray-icons-reloaded
      gnomeExtensions.vitals
      # gnomeExtensions.touch-x better touch screen
    ];

    # fixed Icons missing in gnome in hyrule castle when using stylix (https://discourse.nixos.org/t/icons-missing-in-gnome-applications/49835/6)
    gtk = {
      enable = true;
      #Icon Theme
      iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        # package = pkgs.kdePackages.breeze-icons;
        # name = "Breeze-Dark";
      };
    };

  };
}
