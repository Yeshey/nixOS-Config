{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  c = config.myHome.colorScheme.theme.palette;
  cfg = config.myHome.homeApps.firefox;
in
{
  options.myHome.homeApps.firefox = with lib; {
    enable = mkEnableOption "firefox";
    i2pFirefoxProfile = mkOption {
      type = types.bool;
      default = osConfig.services.i2p.enable || osConfig.mySystem.i2p.enable;
      description = "weather to make a special firefox profile for i2p";
    };
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {

  };
}
