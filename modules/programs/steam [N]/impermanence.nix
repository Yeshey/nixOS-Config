{
  inputs,
  ...
}:
{
  flake.modules.homeManager.steam =
    {
      config,
      ...
    }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          hideMounts = true;
          directories = [
            { directory = ".local/share/Steam"; }
          ];
        };
      };
    };
}
