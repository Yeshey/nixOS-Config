{
  flake.modules.nixos.rclone-mount-onedrive =
    { config, lib, pkgs, ... }:
    {
      environment.persistence."/persist" = {
        hideMounts = true;
        directories =[
          "/root/.config/rclone"
          "/var/lib/restic-flags"
        ];
      };
    };
  flake.modules.homeManager.rclone-mount-onedrive =
    { config, lib, pkgs, ... }:
    {
      home.persistence."/persist/home/${config.home.username}" = {
        directories =[
          ".config/rclone"
          ".local/state/restic-flags"
        ];
        allowOther = true;
      };
    };
}