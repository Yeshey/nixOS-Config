{ inputs, ... }:
{
  flake.modules.nixos.upgrade-on-shutdown =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          files = [
            "/etc/nixos-reboot-update.flag"
          ];
        };
      };
    };
}