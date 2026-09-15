{ inputs, ... }:
{
  flake.modules.nixos.netbird =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          # shared by both netbird-management (management.json, sqlite data/)
          # and netbird-signal (stateless, but WorkingDirectory lives here too)
          {
            directory = "/var/lib/netbird-mgmt";
            mode = "0750";
          }
        ];
      };
    };
}