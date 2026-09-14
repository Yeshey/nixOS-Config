{ inputs, ... }:
{
  flake.modules.nixos.overleaf =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            "/opt/docker/overleaf"
            "/var/log/journal"
          ];
        };
      };
    };
}