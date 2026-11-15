{ inputs, ... }:
{
  flake.modules.homeManager.t3code =
    { config, ... }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".directories = [
          ".t3"
        ];
      };
    };
}