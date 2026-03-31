{
  inputs,
  ...
}:
{
  flake.modules.nixos.ssh =
    { config, ... }:
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.ssh
      ];

      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            { directory = "/etc/ssh"; mode = "0755"; }
          ];
        };
      };
    };

  flake.modules.homeManager.ssh =
    { config, ... }:
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
}