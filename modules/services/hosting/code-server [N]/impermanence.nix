{ inputs, ... }:
{
  flake.modules.nixos.code-server =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent".users.yeshey.directories = [
          ".local/share/code-server/User"
          ".vscode-oss/extensions"
        ];
      };
    };
}