{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = config.myHome.cosmic;
in
{
  imports = [ ];
  options.myHome.cosmic = with lib; {
    enable = mkOption {
      type = types.bool;
      default = (osConfig.mySystem.cosmic.enable or false) || (osConfig.services.xserver.desktopManager.cosmic.enable or false);
      description = "personal cosmic configuration";
    };
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

  };
}
