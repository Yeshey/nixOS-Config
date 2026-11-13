{ inputs, ... }:
{
  flake.modules.nixos.strata =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          # default dataDir uses DynamicUser -> real path is under /var/lib/private
          { directory = "/var/lib/private/strata"; mode = "u=rwx,g=,o="; }
        ];
      };
    };
}