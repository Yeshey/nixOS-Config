{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.cosmic;
in
{
  options.mySystem.cosmic = {
    enable = lib.mkEnableOption "cosmic";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # Enable the COSMIC login manager
    services.displayManager.cosmic-greeter.enable = true;

    # Enable the COSMIC desktop environment
    services.desktopManager.cosmic.enable = true;

    environment = {
      sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1; # for global clipboard - https://wiki.nixos.org/wiki/COSMIC
      systemPackages = [ 

      ];
    };

    programs.firefox.preferences = {
      # disable libadwaita theming for Firefox
      "widget.gtk.libadwaita-colors.enabled" = false;
    };

  };
}
