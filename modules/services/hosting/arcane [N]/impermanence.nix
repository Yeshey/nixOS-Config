{ inputs, ... }:
{
  flake.modules.nixos.arcane =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          "/var/lib/arcane"
        ];
      };
    };
}