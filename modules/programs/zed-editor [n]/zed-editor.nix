{ inputs, ... }:
{
  flake.modules.homeManager.zed-editor =
    {
      imports = with inputs.self.modules.homeManager; [
        zed-editor-client
        zed-editor-host
      ];
    };
}