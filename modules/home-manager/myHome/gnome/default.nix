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
with lib.hm.gvariant;
{
  imports = [ ./dconf.nix ]; # my dconf, doesn't apply to guest user
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

    # Essential (also applies to guest user)
    dconf.settings = {
      "org/gnome/desktop/datetime" = {
        automatic-timezone = false; # SUCKS, gets tricked by VPNs
      };

      "org/gnome/system/location" = { # enables location in gnome
        enabled = true;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        click-method = "areas";
        tap-to-click = true;
      };

      "org/gnome/desktop/privacy" = {
        remove-old-temp-files = true;
        remove-old-trash-files = true;
      };

      "org/gnome/desktop/sound" = {
        allow-volume-above-100-percent = true;
      };

      "org/gnome/desktop/input-sources" = {
        show-all-sources = false;
        sources = [
          (mkTuple [
            "xkb"
            "pt"
          ])
          (mkTuple [
            "xkb"
            "br"
          ])
          (mkTuple [
            "xkb"
            "us"
          ])
        ];
        xkb-options = [ "terminate:ctrl_alt_bksp" ];
      };

      "org/gnome/desktop/wm/preferences" = {
        resize-with-right-button = true;
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;
        disabled-extensions = [
          # "rounded-window-corners@yilozt"
          # "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        ];
        enabled-extensions = [
          "clipboard-history@alexsaveau.dev"
          "clipboard-indicator@tudmotu.com"
          "hibernate-status@dromi"
          "trayIconsReloaded@selfmade.pl"
        ];
      };
    };

  };
}
