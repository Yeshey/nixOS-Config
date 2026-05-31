# idk whats the best way to do this, I should maybe use den man, they even have the conditionalAspect: https://github.com/vic/den/blob/main/templates/ci/modules/features/conditional-config.nix
{
  inputs,
  ...
}:
let 
  username = "yeshey";
in
{
  flake.modules.homeManager.${username} =
    { lib, osConfig, ... }:
    {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];

      config = lib.mkIf (osConfig.systemConstants.isKdePlasma or false) {
        # options: https://nix-community.github.io/plasma-manager/options.xhtml
        programs.plasma = {
          enable = true;
          workspace = {
            clickItemTo = "open";
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