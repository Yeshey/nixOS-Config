{
  flake.modules.nixos.upgrade-on-shutdown =
    { lib, ... }:
    {
      system.autoUpgrade.enable = lib.mkForce false;

      system.autoUpgradeOnShutdown = {
        enable = true;
        flake  = "github:yeshey/nixos-config";
        dates  = "*-*-01,16 06:10:00";
        extraKeepAliveServices = [ "fix-surface-clock.service" "autossh-reverseProxy.service" ];
      };
    };
}
