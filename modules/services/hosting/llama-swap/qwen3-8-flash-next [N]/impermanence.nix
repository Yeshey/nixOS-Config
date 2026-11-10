
{ inputs, ... }:
{
  flake.modules.nixos.llama-swap-qwen3-8-flash-next =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            {
              directory = "/var/lib/private/strata";
              mode = "0750";
            }
          ];
        };
      };
    };
}
