{ inputs, ... }:
{
  flake.modules.nixos.speedtest-tracker =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          "/var/lib/speedtest-tracker/"
        ];
      };
    };
}
