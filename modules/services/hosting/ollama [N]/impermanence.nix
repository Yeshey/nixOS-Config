{ inputs, ... }:
{
  flake.modules.nixos.ollama =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            { directory = "/var/lib/private"; user = "nobody"; group = "nogroup"; mode = "0700"; }
            { directory = "/var/lib/private/ollama"; user = "nobody"; group = "nogroup"; mode = "0700"; }
          ];
        };
      };
    };
}