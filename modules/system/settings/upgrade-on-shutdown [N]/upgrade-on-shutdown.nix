{
  flake.modules.nixos.upgrade-on-shutdown =
    { lib, config, ... }:
    {
      system.autoUpgrade.enable = lib.mkForce false;

      system.autoUpgradeOnShutdown = {
        enable = true;
        flake = "github:yeshey/nixos-config";
        host = config.networking.hostName;
        dates  = "*-*-01,16 06:10:00";
        extraKeepAliveServices = [ "fix-surface-clock.service" "autossh-reverseProxy.service" ];
      };
    };
}
