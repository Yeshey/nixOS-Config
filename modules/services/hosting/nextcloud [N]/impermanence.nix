{ inputs, ... }:
{
  flake.modules.nixos.nextcloud =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            "/var/lib/nextcloud"
            "/var/lib/mysql"
          ];
        };
      };
    };
}