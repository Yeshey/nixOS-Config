{
  inputs,
  ...
}:
let
  username = "yeshey";
in
{
  flake.modules.nixos.hyrulecastle =
    {
      imports = [
        inputs.self.modules.nixos.${username}
      ];

      home-manager.users."${username}" = {
        "${username}".dataStoragePath = "/home/${username}";

        restic-rclone-backups.jobs.mainBackupOneDrive = {
          enable             = true;
          paths              = [ "/home/${username}" ];
          rcloneRemoteName   = "OneDriveISCTE";
          rcloneRemotePath   = "ResticBackups/mainBackupOneDrive";
          passwordFile       = builtins.toFile "restic-password" "123456789";
          initialize         = true;
          startAt            = "*-*-* 14:00:00";
          randomizedDelaySec = "6h";
          prune.keep         = { within = "1d"; daily = 2; weekly = 2; monthly = 6; yearly = 3; };
          exclude            = [ "**/.var" "**/RecordedClasses" "**/Games" ];
        };
        
      };
    };
}