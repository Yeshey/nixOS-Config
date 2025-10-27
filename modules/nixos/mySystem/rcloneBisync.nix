{ config, lib, inputs, pkgs, ... }:

let
  cfg = config.mySystem.rcloneBisync;
in
{
  options.mySystem.rcloneBisync = with lib; {
    enable = mkEnableOption "rcloneBisync";

    mountPoint = mkOption {
      type = types.str;
      default = "/run/media/yeshey/hdd-btrfs/OneDriveISCTE";
      description = "Path where the rclone remote will be mounted. System boot will not fail if the underlying device is not present.";
    };

    remote = mkOption {
      type = types.str;
      default = "onedrive:OneDriveISCTE";
      description = "rclone remote name (eg. 'onedrive:').";
    };

    localPath = mkOption {
      type = types.str;
      default = "/run/media/yeshey/hdd-btrfs/.onedriveISCTE-sync";
      description = "Local folder used for two-way bisync with the remote.";
    };

    user = mkOption {
      type = types.str;
      default = "yeshey";
      description = "User that should own the mount point and run the services. Change if your username differs.";
    };

    bisyncInterval = mkOption {
      type = types.str;
      default = "10m";
      description = "Interval for the bisync timer (systemd OnUnitActiveSec format).";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # ensure rclone/fuse available on the system
    environment.systemPackages = with pkgs; [
      rclone
      rclone-browser
      fuse
      coreutils
    ];

    # create mount & local directories (won't fail boot if device absent)
    systemd.tmpfiles.rules = [
      "d ${cfg.mountPoint} 0755 ${cfg.user} ${cfg.user} - -"
      "d ${cfg.localPath} 0755 ${cfg.user} ${cfg.user} - -"
    ];

    # service that mounts the remote via rclone
    systemd.services."rclone-mount" = {
      description = "Mount OneDrive via rclone";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        # ensure the mountpoint directory exists and is owned by the user
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.mountPoint} && ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.user} ${cfg.mountPoint}";
        ExecStart = "${pkgs.rclone}/bin/rclone mount ${cfg.remote} ${cfg.mountPoint} --vfs-cache-mode writes";
        # try to unmount on stop; allow failure so the service stop doesn't error-out boot
        ExecStop = "${pkgs.fuse}/bin/fusermount -u ${cfg.mountPoint} || true";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    # oneshot service that performs a bisync between localPath <-> remote
    systemd.services."rclone-bisync" = {
      description = "rclone bisync between local folder and OneDrive remote";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.user;
        ExecStart = "${pkgs.rclone}/bin/rclone bisync ${cfg.localPath} ${cfg.remote} --check-access --compare size,modtime --resync";
      };
    };

    # timer to run the bisync service periodically
    systemd.timers."rclone-bisync.timer" = {
      description = "Timer to run rclone-bisync regularly";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnUnitActiveSec = cfg.bisyncInterval;
        Persistent = "true";
      };
    };
  };
}
