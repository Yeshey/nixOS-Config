{ inputs, ... }:
{
  flake.modules.nixos.vnstat =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [{
          directory = "/run/xrdp";
        }];
      };
    };
}