{ inputs, ... }:
{
  flake.modules.nixos.cptr =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            "/var/lib/cptr/workspace"
          ];
        };
      };
    };
}