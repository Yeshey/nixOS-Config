{ inputs, ... }:
{
  flake.modules.nixos.forgejo =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          "/var/lib/forgejo"
        ];
      };
    };
}