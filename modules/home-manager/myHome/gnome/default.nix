{
  config,
  lib,
  pkgs,
  ...
}:

let
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
  };
}
