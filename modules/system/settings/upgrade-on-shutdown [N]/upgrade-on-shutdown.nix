{
  flake.modules.nixos.upgrade-on-shutdown =
    { lib, config, ... }:
    {
      system.autoUpgrade.enable = lib.mkForce false;

      system.autoUpgradeOnShutdown = {
        enable = true;
        flake = "github:yeshey/nixos-config";
        host = config.networking.hostName;
        dates = "Sat *-*-* 07:00:00 UTC";   # CI + 2h
        extraKeepAliveServices = [ "fix-surface-clock.service" ];
      };
    };
}