{ inputs, ... }:
{
  flake.modules.nixos.jev-ultrafast =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          {
            directory = "/var/lib/jev-ultrafast";
            user = "jev-ultrafast";
            group = "jev-ultrafast";
            mode = "0700";
          }
        ];
      };
    };
}