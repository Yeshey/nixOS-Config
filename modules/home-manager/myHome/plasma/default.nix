{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = config.myHome.plasma;
in
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  options.myHome.plasma = with lib; {
    enable = mkOption {
      type = types.bool;
      default = osConfig.mySystem.plasma.enable || osConfig.services.desktopManager.plasma6.enable;
      description = "personal KDE plasma configuration";
    };
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

    # hope it doesn't conflict with stylix 🤞
    # options: https://nix-community.github.io/plasma-manager/options.xhtml
    programs.plasma = {
      enable = true;
      workspace = {
        clickItemTo = "open";
        #lookAndFeel = "org.kde.breezedark.desktop";
        #cursorTheme = "Bibata-Modern-Ice";
        #iconTheme = "Papir";
        #wallpaper = ... # conflicts with stylix
      };
      
      powerdevil = {
        AC = {
          autoSuspend = {
            action = "nothing";
            #idleTimeout = 1000;
          };
          turnOffDisplay = {
            idleTimeout = 600; # 10min
            idleTimeoutWhenLocked = "immediately";
          };
          whenLaptopLidClosed = "doNothing";
        };
        battery = {
          #powerButtonAction = "showLogoutScreen";
          whenSleepingEnter = "standbyThenHibernate";
          whenLaptopLidClosed = "sleep";
        };
        lowBattery = {
          whenSleepingEnter = "standbyThenHibernate";
          whenLaptopLidClosed = "sleep";
        };
      };

      kwin.nightLight = {
        enable = true;
        mode = "location";
        location = {
          latitude = "39,37"; # lisbon
          longitude = "-8,93";
        };
        temperature.night = 2300;
      };

    };

  };
}
