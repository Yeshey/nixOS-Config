{ inputs, ... }:
{
  flake.modules.nixos.openclaw =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [ "/var/lib/openclaw" ];
      };
      # _playground persists with your existing yeshey .setup persistence.
    };
}
