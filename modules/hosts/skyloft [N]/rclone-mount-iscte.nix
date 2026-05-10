{ inputs, ... }:
{
  flake.modules.nixos.skyloft =
    {
      imports = with inputs.self.modules.nixos; [ rclone-mount-onedrive ];

      rclone-mount-onedrive = {
        OneDriveISCTE = {
          enable     = true;
          remote     = "OneDriveISCTE:";
          mountPoint = "/mnt/OneDrive/ISCTE";
          allowOther = true;
        };
      };
      # programs.fuse.userAllowOther is now set automatically by the module
      # when any mount has allowOther = true, so you can drop that line.
      systemd.services.home-manager-yeshey = {
        after = [ "remote-fs.target" ];
        wants = [ "remote-fs.target" ];
      };
    };
}