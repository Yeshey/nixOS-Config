{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.flatpaks;
in
{
  options.mySystem.flatpaks = {
    enable = lib.mkEnableOption "flatpaks";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    services.flatpak.enable = true;

    # allow guest user, and other users to install flatpaks globally
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.user == "guest" &&
            (action.id == "org.freedesktop.Flatpak.app-install" ||
             action.id == "org.freedesktop.Flatpak.runtime-install" ||
             action.id == "org.freedesktop.Flatpak.app-uninstall" ||
             action.id == "org.freedesktop.Flatpak.modify-repo")) {
          return polkit.Result.YES;
        }
      });
    '';
    
    /*
      # More apps # TODO, doesnt work when in gnome??
      services.flatpak.enable = true;
      # needed for flatpak to work
      xdg.portal = {
        enable = true;
        config.common.default = "*";
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-kde
          xdg-desktop-portal-gtk
        ];

        # TODO this should eventually be looked into

          trace: warning: xdg-desktop-portal 1.17 reworked how portal implementations are loaded, you
          should either set `xdg.portal.config` or `xdg.portal.configPackages`
          to specify which portal backend to use for the requested interface.

          https://github.com/flatpak/xdg-desktop-portal/blob/1.18.1/doc/portals.conf.rst.in

          If you simply want to keep the behaviour in < 1.17, which uses the first
          portal implementation found in lexicographical order, use the following:

          xdg.portal.config.common.default = "*";
    */

    #configPackages = [pkgs.gnome.gnome-session]; # TODO, how to do this?
    /*
      config =
      {
        common = {
          default = [
            "gtk"
          ];
        };
        pantheon = {
          default = [
            "pantheon"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };
        x-cinnamon = {
          default = [
            "xapp"
            "gtk"
          ];
        };
      };
    */
    #};
  };
}
