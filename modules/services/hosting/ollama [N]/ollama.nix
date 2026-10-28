{ inputs, ... }:
{
  flake.modules.nixos.ollama =
    { pkgs, config, ... }:
    {
      services.ollama = {
        package = pkgs.unstable.ollama;
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        environmentVariables = {
          OLLAMA_ORIGINS = "*";
          # OLLAMA_DEBUG = "1";
        };
      };
    };
}