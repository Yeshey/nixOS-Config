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
  # imports = [ ./dconf.nix ];
  options.myHome.gnome = with lib; {
    enable = mkOption {
      type = types.bool;
      default = osConfig.mySystem.gnome.enable || osConfig.services.xserver.desktopManager.gnome.enable;
      description = "personal gnome configuration";
    };
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {
    home.packages = with pkgs; [
      # For gnome
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.burn-my-windows
      gnomeExtensions.hibernate-status-button
      gnomeExtensions.tray-icons-reloaded
    ];
  };
}
