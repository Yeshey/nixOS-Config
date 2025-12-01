{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.androidDevelopment;
in
{
  options.mySystem.androidDevelopment = with lib; {
    enable = mkEnableOption "androidDevelopment";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    users.users.${config.mySystem.user}.extraGroups = [ "adbusers" ];
    programs.adb.enable = true;
    services.udev.packages = with pkgs; [ ];
  };
}
