{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.waydroid;
in
{
  options.mySystem.waydroid = {
    enable = lib.mkEnableOption "waydroid";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
  };
}
