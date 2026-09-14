{ inputs, ... }:
{
  flake.modules.nixos.open-webui =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            { directory = "/var/lib/private/open-webui"; user = "nobody"; group = "nogroup"; mode = "0700"; }
          ];
        };
      };
    };
}