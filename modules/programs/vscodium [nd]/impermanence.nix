{
  inputs,
  ...
}:
{
  flake.modules.homeManager.vscodium =
    {
      config,
      ...
    }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            ".local/share/code-server/User"
            ".vscode-oss/extensions" 
          ];
        };
      };
    };
}
