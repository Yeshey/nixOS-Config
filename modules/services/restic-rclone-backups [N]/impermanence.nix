{
  inputs,
  ...
}:
{
  flake.modules.homeManager.restic-rclone-backups =
    { config, ... }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          hideMounts = true;
          directories = [
            ".local/state/restic-flags"
          ];
        };
      };
    };

  flake.modules.nixos.restic-rclone-backups =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            "/var/lib/restic-flags"
          ];
        };
      };
    };
}