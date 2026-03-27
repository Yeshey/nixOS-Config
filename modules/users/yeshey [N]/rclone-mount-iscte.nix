{ inputs, ... }:
{
  flake.modules.homeManager.yeshey =
    { config, ... }:
    {
      imports = [ inputs.self.modules.homeManager.rclone-mount-onedrive ];

      rclone-mount-onedrive = {
        enable     = true;
        mountPoint = "${config.home.homeDirectory}/OneDrive/ISCTE";
        remote     = "OneDriveISCTE:";
        allowOther = false;
      };
    };
}