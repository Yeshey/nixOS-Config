{ inputs, ... }:
{
  flake.modules.nixos.overleaf =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            "/var/lib/docker"
            "/opt/docker/overleaf"
            "/var/lib/docker-compose"
            "/var/log/journal"
          ];
        };
      };
    };
}