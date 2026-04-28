# restic impermanence
{
  inputs,
  ...
}:
{
  flake.modules.homeManager.restic-rclone-backups-impermanence =
    { config, ... }:
    {
      imports = [
        inputs.self.modules.homeManager.rclone-config-impermanence
      ];

      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          hideMounts = true;
          directories = [
            ".local/state/restic-flags"
          ];
        };
      };
    };

  flake.modules.nixos.restic-rclone-backups-impermanence =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            "/var/lib/restic-flags"
            { directory = "/root/.config/rclone"; mode = "0700"; }
          ];
        };
      };
    };
}