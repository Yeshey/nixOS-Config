{ inputs, ... }:
{
  flake.modules.nixos.pithagoras =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          "/var/lib/pithagoras/workspaces"
        ];
      };
    };
}