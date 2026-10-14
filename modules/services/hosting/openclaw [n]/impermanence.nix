{ inputs, ... }:
{
  flake.modules.nixos.openclaw =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          users.yeshey.directories = [
            ".openclaw"
          ];
        };
      };
    };
}