{ inputs, ... }:
{
  flake.modules.nixos.headscale =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          # Headscale's entire state: SQLite DB, noise private key,
          # DERP private key (if enabled later). Everything lives here.
          # Without this, every reboot wipes all users, nodes, and keys.
          {
            directory = "/var/lib/headscale";
            user = "headscale";
            group = "headscale";
            mode = "0750";
          }
          {
            directory = "/var/lib/tailscale";
            mode = "0700";
          }
        ];
      };
    };
}