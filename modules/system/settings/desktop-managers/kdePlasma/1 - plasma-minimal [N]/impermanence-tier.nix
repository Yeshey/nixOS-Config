{
  inputs,
  ...
}:
{
  flake.modules.homeManager.plasma-minimal-tier =
    {
      config,
      ...
    }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          hideMounts = true;
          directories = [
            ".local/share/baloo" # KDE plasma files index
          ];
        };
      };
    };
}
