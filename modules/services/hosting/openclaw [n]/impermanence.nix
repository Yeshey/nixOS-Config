{ inputs, ... }:
{
  flake.modules.nixos.openclaw =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [ "/var/lib/openclaw" ];
      };
      # Includes the agent's home, repository checkout, requests, and logs.
    };
}
