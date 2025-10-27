{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.rcloneBisync;
  user = cfg.user;
  home = "/home/${user}";
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
      default = "OneDriveISCTE:";
      description = "rclone remote/remote-path (eg. 'onedrive:' or 'onedrive:SomeFolder').";
    };

    localPath = mkOption {
      type = types.str;
      default = "/run/media/yeshey/hdd-btrfs/.onedriveISCTE-sync";
      description = "Local folder on the external drive used for two-way bisync with the remote. Keep this on the external drive to avoid using home partition.";
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

    allowOther = mkOption {
      type = types.bool;
      default = false;
      description = "If true, add --allow-other to rclone mount (requires user_allow_other in /etc/fuse.conf).";
    };

    firstRun = mkOption {
      type = types.bool;
      default = false;
      description = "Set to true for the first sync or when recovering from errors. This uses --resync which can overwrite data.";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    environment.systemPackages = with pkgs; [ 
      unstable.rclone-browser
      rclone 
      fuse 
    ];

    # ----------  NO ROOT DIRECTORY CREATION ANYWHERE  ----------
    # systemd.tmpfiles.rules = [ ];   <-- GONE
    # preStart = ''mkdir -p ...'';    <-- GONE from both services

    systemd.user.services = {

      rclone-mount = {
        description = "OneDrive rclone mount (user session)";
        wantedBy = [ "default.target" ];
        after    = [ "network-online.target" ];
        wants    = [ "network-online.target" ];

        # no preStart, no postStop mkdir
        script = ''
          exec ${pkgs.rclone}/bin/rclone mount \
            ${lib.escapeShellArg cfg.remote} \
            ${lib.escapeShellArg cfg.mountPoint} \
            --vfs-cache-mode writes \
            --vfs-read-chunk-size 128M \
            --vfs-read-chunk-size-limit off \
            ${lib.optionalString cfg.allowOther "--allow-other"} \
            --daemon \
            --config ${home}/.config/rclone/rclone.conf
        '';

        postStop = ''
          ${pkgs.fuse}/bin/fusermount -u ${lib.escapeShellArg cfg.mountPoint} || true
        '';

        serviceConfig = {
          Type       = "forking";
          PIDFile    = "${home}/.cache/rclone/rclone.pid";
          Restart    = "on-failure";
          RestartSec = "10s";
        };
      };

      rclone-bisync = {
        description = "OneDrive bisync";
        requires    = [ "rclone-mount.service" ];
        after       = [ "rclone-mount.service" ];

        # no preStart mkdir
        script = ''
          exec ${pkgs.rclone}/bin/rclone bisync \
            ${lib.escapeShellArg cfg.localPath} \
            ${lib.escapeShellArg cfg.remote} \
            --check-access \
            --compare size,modtime \
            --verbose \
            --config ${home}/.config/rclone/rclone.conf \
            ${lib.optionalString cfg.firstRun "--resync"}
        '';

        serviceConfig.Type = "oneshot";
      };
    };

    systemd.user.timers.rclone-bisync = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec       = "2m";
        OnUnitActiveSec = cfg.bisyncInterval;
        Persistent      = true;
        Unit            = "rclone-bisync.service";
      };
    };

    users.users.${user}.linger = true;
  };
}