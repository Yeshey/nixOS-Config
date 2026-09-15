{ inputs, ... }:
{
  flake.modules.nixos.litellm =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          "/var/lib/private/litellm"
        ];
      };
    };
}