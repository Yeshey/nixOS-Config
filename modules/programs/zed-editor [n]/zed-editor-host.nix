{ ... }:
{
  flake.modules.homeManager.zed-editor-host =
    { pkgs, lib, ... }:
    {
      programs.zed-editor = {
        enable = true;
        package = lib.mkDefault pkgs.unstable.zed-editor;
        installRemoteServer = true;
      };
    };
}