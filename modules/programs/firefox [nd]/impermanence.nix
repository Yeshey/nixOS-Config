{
  inputs,
  ...
}:
{
  flake.modules.homeManager.firefoxBrowser =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            ".mozilla/firefox"
          ];
        };
      };
    };
}
