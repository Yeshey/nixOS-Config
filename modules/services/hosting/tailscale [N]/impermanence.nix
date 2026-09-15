{ inputs, ... }:
{
  flake.modules.nixos.tailscale =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          {
            directory = "/var/lib/tailscale";
            mode = "0700";
          }
        ];
      };
    };
}