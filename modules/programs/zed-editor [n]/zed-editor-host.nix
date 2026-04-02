{ ... }:
{
  flake.modules.homeManager.zed-editor-host =
    { pkgs, ... }:
    {
      programs.zed-editor = {
        enable = true;
        package = pkgs.unstable.zed-editor;
        installRemoteServer = true;
      };
    };
}