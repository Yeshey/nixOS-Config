{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.budgie;
in
{
  options.mySystem.budgie = {
    enable = lib.mkEnableOption "budgie";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # services = {
    #   desktopManager.budgie.enable = true;
    #   displayManager.lightdm.enable = true;
    #   xserver = {
    #     enable = true;
    #   };
    # };

    services = {
      xserver = {
        enable = true;
        desktopManager.budgie.enable = true;
        displayManager.lightdm.enable = true;
      };
    };

  };
}
