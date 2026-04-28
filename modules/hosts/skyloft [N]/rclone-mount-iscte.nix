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
    };
}