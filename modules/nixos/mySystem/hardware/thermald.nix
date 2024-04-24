{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.hardware.thermald;
in
{
  options.mySystem.hardware.thermald = {
    enable = lib.mkEnableOption "thermald";
    thermalConf = lib.mkOption {
      type = lib.types.path;
      example = ./thermal-conf.xml;
    };
  };

  config = lib.mkIf cfg.enable {

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
          --config-file ${cfgt.configFile} \
      '';
  };
}
