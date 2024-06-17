{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.mySystem.hardware.thermald;
in
{
  options.mySystem.hardware.thermald = {
    enable = mkEnableOption "thermald";
    thermalConf = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = ./thermal-conf.xml;
    };
  };

  config = mkIf (config.mySystem.enable && config.mySystem.hardware.enable && cfg.enable) {

    # Manage Temperature, prevent throttling
    # https://github.com/linux-surface/linux-surface/issues/221
    # laptop thermald with: https://github.com/intel/thermal_daemon/issues/42#issuecomment-294567400
    services.power-profiles-daemon.enable = true;
    services.thermald = {
      debug = false;
      enable = true;
      configFile = cfg.thermalConf; # (https://github.com/linux-surface/linux-surface/blob/master/contrib/thermald/thermal-conf.xml)
    };
    systemd.services.thermald.serviceConfig.ExecStart =
      let # running with --adaptive ignores the config file. Issue raised: https://github.com/NixOS/nixpkgs/issues/201402
        cfgt = config.services.thermald;
      in
      lib.mkForce ''
        ${cfgt.package}/sbin/thermald \
          --no-daemon \
          ${if cfgt.configFile != null then "--config-file ${cfgt.configFile}" else "--adaptive"} \
      '';
  };
}
