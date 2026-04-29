{ inputs, ... }:
{
  flake.modules.nixos.skyloft =
    { config, ... }:
    {
      imports = with inputs.self.modules.nixos; [ rclone-mount-onedrive ];

      rclone-mount-onedrive = {
        enable     = true;
        remote     = "OneDriveISCTE:";
        mountPoint = "/mnt/OneDrive/ISCTE";
      };
      programs.fuse.userAllowOther = true; # so syncthing and stuff can access the mount
      systemd.services.home-manager-yeshey = {
        after = [ "rclone-mount-onedrive.service" ];
        wants = [ "rclone-mount-onedrive.service" ];
      };
    };
}