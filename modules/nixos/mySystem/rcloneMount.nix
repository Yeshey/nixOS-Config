{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.rcloneMount;
  user = cfg.user;
  home = "/home/${user}";
in
{
  options.mySystem.rcloneMount = with lib; {
    enable = mkEnableOption "rcloneMount";

    mountPoint = mkOption {
      type = types.str;
      default = "/home/yeshey/OneDriveISCTE";
      description = "Path where the rclone remote will be mounted. System boot will not fail if the underlying device is not present.";
    };

    remote = mkOption {
      type = types.str;
      default = "OneDriveISCTE:";
      description = "rclone remote/remote-path (eg. 'onedrive:' or 'onedrive:SomeFolder').";
    };

    user = mkOption {
      type = types.str;
      default = "yeshey";
      description = "User that should own the mount point and run the services. Change if your username differs.";
    };

    allowOther = mkOption {
      type = types.bool;
      default = true;  # Changed to true by default to fix permission issues
      description = "If true, add --allow-other to rclone mount (requires user_allow_other in /etc/fuse.conf).";
    };

    firstRun = mkOption {
      type = types.bool;
      default = false;
      description = "Set to true for the first sync or when recovering from errors. This uses --resync which can overwrite data.";
    };

    idleTimeout = mkOption {
      type = types.int;
      default = 600;
      description = "Time in seconds before the mount is automatically unmounted due to inactivity.";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    environment.systemPackages = with pkgs; [
      unstable.rclone-browser
      rclone
    ];

    # Enable user_allow_other in fuse.conf (required for allow_other option)
    programs.fuse.enable = true;
    programs.fuse.userAllowOther = true;

    /*
      ----------------------------------------------------------
      SYSTEMD MOUNT UNIT (using rclone as mount helper)
      ----------------------------------------------------------
    */
    # rclone Documentation on how to do this: https://rclone.org/commands/rclone_mount/#rclone-as-unix-mount-helper
    # check logs: journalctl -fu home-yeshey-OneDriveISCTE.mount
    systemd.mounts = [{
      description = "OneDrive rclone mount";
      what = cfg.remote;
      where = cfg.mountPoint;
      type = "rclone";
      
      mountConfig = {
        Options = lib.concatStringsSep "," (
          [
            "_netdev"
            "args2env"
            "vfs-cache-mode=full"
            "vfs-cache-max-size=20G"
            "vfs-cache-max-age=168h"
            "vfs-cache-min-free-space=5G"
            "no-check-certificate"
            #"disable-http2"
            #"s3-no-check-bucket"
            #"s3-no-head-object"
            "config=${home}/.config/rclone/rclone.conf"
            "env.PATH=/run/wrappers/bin"
          ]
          ++ lib.optional cfg.allowOther "allow_other"
        );
      };

      # Network dependency - including your custom service
      after = [ "my-network-online.service" "network-online.target" ];
      wants = [ "my-network-online.service" "network-online.target" ];
      requires = [ "my-network-online.service" "network-online.target" ];
    }];

    /*
      ----------------------------------------------------------
      SYSTEMD AUTOMOUNT UNIT
      ----------------------------------------------------------
    */
    systemd.automounts = [{
      description = "OneDrive rclone automount";
      where = cfg.mountPoint;
      wantedBy = [ "multi-user.target" ];
      
      automountConfig = {
        TimeoutIdleSec = toString cfg.idleTimeout;
      };
    }];


  };
}