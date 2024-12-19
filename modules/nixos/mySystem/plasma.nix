{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.plasma;
in
{
  options.mySystem.plasma = {
    enable = lib.mkEnableOption "plasma";
    defaultSession = lib.mkOption {
      type = lib.types.str;
      default = "plasma";
      example = "plasmax11";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    # KDE Plasma
    #programs.qt5ct.enable = true;
/*
    qt = {
      enable = true;
      platformTheme = "";
      style = "adwait";
    }; */
/*
    qt = {
      enable = true;
      platformTheme = "qt5ct";
      style = "breeze";
    };*/
    /*
    gtk = {
      #enable = true;
      theme = {
        name = "Breeze-Dark";
        package = pkgs.libsForQt5.breeze-gtk;
      };
    };*/

    services = {
      xserver.enable = lib.mkOverride 1010 true; # Enable the X11 windowing system.
      displayManager = {
        autoLogin.enable = lib.mkOverride 1010 true;
        autoLogin.user = lib.mkOverride 1010 "${config.mySystem.user}"; # TODO
        sddm = {
	        wayland.enable = true;
          enable = lib.mkOverride 1010 true;
        };
        defaultSession = lib.mkOverride 1010 cfg.defaultSession; # "none+bspwm" or "plasma"
      };
      desktopManager.plasma6 = {
        enable = lib.mkOverride 1010 true;
        enableQt5Integration = true;
        # supportDDC = true; # doesnt work with nvidia # to support changing brightness for external monitors (https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800)
      };
      # windowManager.bspwm.enable = true; # but doesn't work
    };
    environment.systemPackages = with pkgs; [
      # FOR PLASMA DESKTOP
      sddm-kcm # for sddm configuration in settings
      unrar # also to extract .rar with ark in KDE # unrar x Lab5.rar
      ocs-url # to install plasma widgets # do installed things not work?
    ];
  };
}
