{
  inputs,
  ...
}:
{
  flake.modules.homeManager.syncthing =
    {
      config,
      ...
    }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          hideMounts = true;
          directories = [
            ".config/syncthing"
          ];
        };
      };
    };
}
