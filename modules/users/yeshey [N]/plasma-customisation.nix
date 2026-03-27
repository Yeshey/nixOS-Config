{ inputs, ... }:
let
  username = "yeshey";
in
{
  flake.modules.homeManager.${username} = 
    { pkgs, lib, config, osConfig, ... }: 
    let
      isKdePlasma = osConfig.services.desktopManager.plasma6.enable or false;
    in
    {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];

      options.${username}.enableKdePlasmaCustomizations = lib.mkOption {
        type = lib.types.bool;
        default = isKdePlasma || false; # osConfig detects plasma in NixOS, and you can override in HM standalone
        description = "Enable ${username}'s KDE Plasma customizations. Auto-detected on NixOS, set manually for standalone HM.";
      };

      config = lib.mkIf config.${username}.enableKdePlasmaCustomizations {
        home.packages = [ pkgs.banana-cursor ];

        # options: https://nix-community.github.io/plasma-manager/options.xhtml
        programs.plasma = {
          enable = true;
          workspace = {
            clickItemTo = "open";
            cursor.theme = "Banana";
          };
          
          powerdevil = {
            AC = {
              autoSuspend = {
                action = "nothing";
              };
              turnOffDisplay = {
                idleTimeout = 600; # 10min
                idleTimeoutWhenLocked = "immediately";
              };
              whenLaptopLidClosed = "doNothing";
            };
            battery = {
              whenSleepingEnter = "standbyThenHibernate";
              whenLaptopLidClosed = "sleep";
            };
            lowBattery = {
              whenSleepingEnter = "standbyThenHibernate";
              whenLaptopLidClosed = "sleep";
            };
          };
        };
      };
    };
}