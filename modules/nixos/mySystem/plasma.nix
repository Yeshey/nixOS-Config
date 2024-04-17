{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.plasma;
in
{
  options.mySystem.plasma = {
    enable = lib.mkEnableOption "plasma";
  };

  config = lib.mkIf cfg.enable {
    # KDE Plasma
    services.xserver = {
        enable = true; # Enable the X11 windowing system.
        displayManager = {
          autoLogin.enable = true;
          autoLogin.user = "yeshey"; # TODO
          sddm = {
              enable = true;
          };
          defaultSession = "plasma"; # "none+bspwm" or "plasma"
        };
        desktopManager.plasma5 = {
          enable = true;
          # supportDDC = true; # doesnt work with nvidia # to support changing brightness for external monitors (https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800)
        };
        # windowManager.bspwm.enable = true; # but doesn't work
    };
    environment.systemPackages = with pkgs; [
      # FOR PLASMA DESKTOP
      scrot # for plasma config saver widget
      kdialog # for plasma config saver widget
      ark # Compress and Uncompress files
      sddm-kcm # for sddm configuration in settings
      kate # KDEs notepad    
    ];

  };
}
