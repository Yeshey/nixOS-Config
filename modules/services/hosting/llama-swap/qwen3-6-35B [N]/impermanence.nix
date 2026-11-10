{ inputs, ... }:
{
  flake.modules.nixos.llama-swap-qwen-3-6 =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            {
              directory = "/var/cache/llama-swap";
              user = "llama-swap";
              group = "llama-swap";
              mode = "0750";
            }
            {
              directory = "/var/lib/llama-swap";
              user = "llama-swap";
              group = "llama-swap";
              mode = "0750";
            }
          ];
        };
      };
    };
}