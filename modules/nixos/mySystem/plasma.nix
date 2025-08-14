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
    x11 = lib.mkEnableOption "x11";
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

    # For hotspot to connect (in KDE plasma)
    # https://github.com/NixOS/nixpkgs/issues/263359
    networking.firewall.allowedUDPPorts = [ 67 68 53 
    ];
    networking.firewall.allowedTCPPorts = [ 67 68 53 
    ];

    environment.sessionVariables = rec {
      #KWIN_FORCE_SW_CURSOR="1";
    };
    services = {
      xserver = lib.mkIf cfg.x11 {
        displayManager.startx.enable = true;
        enable = true;    # X11 because setting up Wayland is more complicated than it is worth for me.
      };
      desktopManager.plasma6.enable = true;
      displayManager = {
        #autoLogin.enable = true;
        #autoLogin.user = config.mySystem.user;
        sddm.enable = true;
        defaultSession = lib.mkForce "plasma";
      };
    };

    environment.systemPackages = with pkgs; [
      # FOR PLASMA DESKTOP
      kdePackages.sddm-kcm # for sddm configuration in settings
      unrar # also to extract .rar with ark in KDE # unrar x Lab5.rar
      ocs-url # to install plasma widgets # do installed things not work?
    ];
  };
}
