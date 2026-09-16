{ inputs, ... }:
{
  flake.modules.nixos.sops-nix =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            "/var/lib/sops-nix"
          ];
        };
      };
    };

  flake.modules.homeManager.sops-nix =
    { config, ... }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            ".config/sops/age"
          ];
        };
      };
    };
}