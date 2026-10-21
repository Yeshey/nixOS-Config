{ inputs, ... }:
{
  flake.modules.nixos.ollama =
    { pkgs, ... }:
    {
      services.ollama = {
        package = pkgs.unstable.ollama;
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        environmentVariables = {
          OLLAMA_ORIGINS = "*";
        };
      };
    };
}