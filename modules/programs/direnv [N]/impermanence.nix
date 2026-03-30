{
  inputs,
  ...
}:
{
  flake.modules.homeManager.direnv =
    {
      config,
      ...
    }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          hideMounts = true;
          directories = [
            ".local/share/direnv"
          ];
        };
      };
    };
}
