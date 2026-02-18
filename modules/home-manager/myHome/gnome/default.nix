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
      default = (osConfig.mySystem.gnome.enable or false) || (osConfig.services.desktopManager.gnome.enable or false);
      description = "personal gnome configuration";
    };
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

    home.packages = with pkgs; [
      networkmanagerapplet # Has for example "Automatically connect to VPN when using this connection"
      gnomeExtensions.burn-my-windows
      gnomeExtensions.appindicator # system tray
      gnomeExtensions.system-monitor # official gnome extension
      gnomeExtensions.user-themes # # official gnome extension
      unstable.gnomeExtensions.copyous # The best clipboard manager
      gnomeExtensions.night-theme-switcher

      banana-cursor # for the cursor
    ];

    # Essential (also applies to guest user)
    dconf.settings = {
      # "org/gnome/desktop/datetime" = {
      #   automatic-timezone = false; # SUCKS, gets tricked by VPNs
      # }; 

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
        input-feedback-sounds = true;
      };

      "org/gnome/desktop/wm/keybindings" = {
        show-desktop = [ "<Super>d" ];
        switch-windows = [ "<Alt>Tab" ];
        switch-windows-backward = [ "<Shift><Alt>Tab" ];
        switch-applications = [ ];
        switch-applications-backward = [ ]; # Optional: also disable reverse app switching
      };

      "org/gnome/shell/window-switcher" = {
        current-workspace-only = false;
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

      "org/gnome/desktop/interface" = {
        clock-show-seconds = true;
        clock-show-weekday = true;
        show-battery-percentage = true;
        cursor-theme = "Banana";  # Add this line
      };

      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
        resize-with-right-button = true;
      };

      "org/gnome/nautilus/preferences" = {
        show-create-link = true;
        show-delete-permanently = true;
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;
        disabled-extensions = [
          # "rounded-window-corners@yilozt"
          # "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        ];
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com" # system tray
          "system-monitor@gnome-shell-extensions.gcampax.github.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "copyous@boerdereinar.dev"
          "nightthemeswitcher@romainvigier.fr"
        ];
      };

      "org/gnome/shell/extensions/appindicator" = {
        tray-pos = "left";
      };

      "org/gnome/shell/extensions/system-monitor" = {
        show-download = false;
        show-upload = false;
      };
    };

  };
}
