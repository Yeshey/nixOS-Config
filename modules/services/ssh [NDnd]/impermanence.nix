{
  inputs,
  ...
}:
{
  flake.modules.homeManager.ssh =
    {
      config,
      ...
    }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          hideMounts = true;
          directories = [
            { directory = ".ssh"; mode = "0700"; }
          ];
        };
      };
    };

  flake.modules.nixos.impermanence =
    { ... }:
    {
      environment.persistence."/persistent" = {
        directories = [
          { directory = "/etc/ssh"; mode = "0755"; }
        ];
      };
    };
}
