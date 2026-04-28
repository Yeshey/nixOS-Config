{
  inputs,
  ...
}:
{
  flake.modules.homeManager.rclone-mount-onedrive =
    { config, ... }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          hideMounts = true;
          directories = [
            ".config/rclone"
          ];
        };
      };
    };
}