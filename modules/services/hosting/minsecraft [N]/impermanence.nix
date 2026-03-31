{ inputs, ... }:
{
  flake.modules.nixos.minecraft =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            { directory = "/srv/minecraft"; user = "minecraft"; group = "minecraft"; mode = "u=rwx,g=rx,o="; }
          ];
        };
      };
    };
}