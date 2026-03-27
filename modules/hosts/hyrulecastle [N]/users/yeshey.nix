{
  inputs,
  ...
}:
let
  username = "yeshey";
in
{
  flake.modules.nixos.hyrulecastle =
    { lib, config, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        inputs.self.modules.nixos.${username}
        restic-rclone-backups
      ];

      home-manager.users."${username}" = {
        "${username}".dataStoragePath = "/mnt/DataDisk";
      };

      restic-rclone-backups.jobs.mainBackupOneDrive = {
        enable           = true;
        user             = "yeshey";
        paths            = [ "/home/yeshey" ];
        rcloneRemoteName = "OneDriveISCTE";
        rcloneRemotePath = "ResticBackups/mainBackupOneDrive";
        rcloneConfigFile = "/home/yeshey/.config/rclone/rclone.conf";
        passwordFile     = builtins.toFile "restic-password" "123456789";
        initialize       = true;
        startAt          = "*-*-* 14:00:00";
        randomizedDelaySec = "6h";
        prune.keep = { within = "1d"; daily = 2; weekly = 2; monthly = 6; yearly = 3; };
        exclude = [ "**/.var" "**/RecordedClasses" "**/Games" ];
      };
    };
}
