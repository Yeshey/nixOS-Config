{ inputs, ... }:
{
  flake.modules.nixos.xrdp =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          "/etc/xrdp/"
        ];
      };
    };
}