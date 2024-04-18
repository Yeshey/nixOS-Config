{ config, pkgs, user, location, lib, ... }:

{
  # Manage Temperature, prevent throttling
  # https://github.com/linux-surface/linux-surface/issues/221
  # laptop thermald with: https://github.com/intel/thermal_daemon/issues/42#issuecomment-294567400
  services.power-profiles-daemon.enable = true;
  services.thermald = {
    debug = false;
    enable = true;
    configFile = ./../thermal-conf.xml; #(https://github.com/linux-surface/linux-surface/blob/master/contrib/thermald/thermal-conf.xml)
  };
  systemd.services.thermald.serviceConfig.ExecStart = let # running with --adaptive ignores the config file. Issue raised: https://github.com/NixOS/nixpkgs/issues/201402
    cfg = config.services.thermald;
      in lib.mkForce ''
          ${cfg.package}/sbin/thermald \
            --no-daemon \
            --config-file /home/yeshey/.setup/hosts/laptop/configFiles/thermal-conf.xml \
        '';
  # TODO above was like so:
  # user = "yeshey";
  # location = "/home/${user}/.setup"; # "$HOME/.setup"
  /* in lib.mkForce ''
          ${cfg.package}/sbin/thermald \
            --no-daemon \
            --config-file ${location}/hosts/laptop/configFiles/thermal-conf.xml \
        '';
        */
}