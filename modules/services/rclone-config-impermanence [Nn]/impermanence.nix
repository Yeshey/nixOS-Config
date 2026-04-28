{
  inputs,
  ...
}:
{
  flake.modules.homeManager.rclone-config-impermanence =
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