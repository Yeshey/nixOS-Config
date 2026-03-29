{ inputs, ... }:
{
  flake.modules.nixos.vnstat =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [{
          directory = "/var/lib/vnstat";
          user      = "vnstatd";
          group     = "vnstatd";
          mode      = "0755";
        }];
      };
    };
}