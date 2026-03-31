{ inputs, ... }:
{
  flake.modules.nixos.kubo =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            { directory = "/var/lib/ipfs"; user = "ipfs"; group = "ipfs"; mode = "u=rwx,g=rx,o="; }
          ];
        };
      };
    };
}