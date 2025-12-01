{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.gaming;
in
{
  options.myHome.homeApps.gaming = with lib; {
    enable = mkEnableOption "gaming";
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {
    home.packages = with pkgs; [

    ];

  };
}
