{ inputs, ... }:
{
  flake.modules.nixos.jupyter =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            { directory = "/var/lib/jupyter"; user = "jupyter"; group = "jupyter"; mode = "u=rwx,g=rx,o="; }
          ];
        };
      };
    };
}