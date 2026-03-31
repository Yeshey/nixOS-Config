{ inputs, ... }:
{
  flake.modules.nixos.openhands =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            "/home/yeshey/.openhands-state"
          ];
        };
      };
    };
}