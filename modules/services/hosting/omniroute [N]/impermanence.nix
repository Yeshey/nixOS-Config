{ inputs, ... }:
{
  flake.modules.nixos.omniroute =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          "/var/lib/omniroute"
        ];
      };
    };
}