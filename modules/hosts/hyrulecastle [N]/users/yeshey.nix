{
  inputs,
  ...
}:
let
  username = "yeshey";
  myStoragePath = "/home/${username}";
in
{
  flake.modules.nixos.hyrulecastle =
    { lib, ... }:
    {
      imports = [
        inputs.self.modules.nixos.${username}
      ];
      options.yeshey.dataStoragePath = lib.mkOption { type = lib.types.str; };
      config = {
        yeshey.dataStoragePath = myStoragePath;

        home-manager.users."${username}" = {
          "${username}".dataStoragePath = myStoragePath;

          restic-rclone-backups.jobs.mainBackupOneDrive = {
            enable             = true;
            paths              = [ "/home/${username}" ];
            rcloneRemoteName   = "OneDriveISCTE";
            rcloneRemotePath   = "Backups/ResticBackups/mainBackupOneDrive";
            passwordFile       = builtins.toFile "restic-password" "123456789";
            initialize         = false;
            startAt            = "*-*-1/2 14:00:00";
            randomizedDelaySec = "1h";
            prune.keep         = { within = "1d"; daily = 2; weekly = 2; monthly = 6; yearly = 3; };
            exclude            = [ "**/.var" "**/RecordedClasses" "**/Games" ];
          };
        };
      };
    };
}