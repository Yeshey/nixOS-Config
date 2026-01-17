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
    ];

    programs.fuse.enable = true;
    programs.fuse.userAllowOther = true;

    # Ensure the mountpoint and cache dir exist on boot (owner = user, group = users)
    systemd.tmpfiles.rules = lib.mkForce [
      # create mount point (cfg.mountPoint) and /mnt/rclonecache with desired perms and owner
      "d ${cfg.mountPoint} 0755 ${user} users - -"
      "d /mnt/rclonecache 0755 ${user} users - -"
    ];

    systemd.services.rclone-onedrive = {
      description = "RClone Service";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      # keep hibernation/sleepable like your example
      before = [ "sleep.target" ];

      # Unit-level AssertPathIsDirectory like in your example
      unitConfig = {
        AssertPathIsDirectory = cfg.mountPoint;
      };

      # ExecStart is provided via `script` (matches example ExecStart invocation)
      script = ''
        exec ${pkgs.rclone}/bin/rclone mount ${lib.escapeShellArg cfg.remote} ${lib.escapeShellArg cfg.mountPoint} \
          --allow-other \
          --dir-cache-time 5000h \
          --syslog \
          --poll-interval 10s \
          --umask 0000 \
          --user-agent OneDrive \
          --cache-dir=/mnt/rclonecache \
          --vfs-cache-mode full \
          --volname onedrive \
          --vfs-cache-max-size 60G \
          --vfs-read-chunk-size 128M \
          --vfs-read-ahead 2G \
          --vfs-cache-max-age 5000h \
          --bwlimit-file 100M
      '';

      environment = [
        "RCLONE_CONFIG=/home/${user}/.config/rclone/rclone.conf"
        "PATH=/run/wrappers/bin/:$PATH"
      ];

      serviceConfig = {
        Type = "notify";
        RestartSec = "10";
        # EXACTLY like your example's single cleanup line (adapted to cfg.mountPoint)
        ExecStop = "${pkgs.fuse3}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint}";
        Restart = "on-failure";

        # ---- NixOS-specific permission bits needed for FUSE ----
        DeviceAllow = "/dev/fuse rwm";
        CapabilityBoundingSet = "CAP_SYS_ADMIN";
        AmbientCapabilities = "CAP_SYS_ADMIN";

        # run as provided user & group
        User = user;
        Group = "users";
      };
    };

    # Make it so every time there is a Network change the rclone mount restarts
    # Don't restart on network changes during sleep
    # environment.etc."NetworkManager/dispatcher.d/50-rclone-restart".text = ''
    #   #!/bin/sh
      
    #   ACTION="$2"
      
    #   # Skip if going to sleep (lock file exists)
    #   [ -f /tmp/rclone-sleep-lock ] && exit 0
      
    #   case "$ACTION" in
    #     up|down|vpn-up|vpn-down|connectivity-change|dhcp4-change|dhcp6-change)
    #       /run/current-system/sw/bin/systemctl restart --no-block rclone-mount.service
    #       ;;
    #   esac
    # '';

    # environment.etc."NetworkManager/dispatcher.d/50-rclone-restart".mode = "0755";

    # # Create lock file before sleep, remove after wake
    # systemd.services.rclone-sleep-handler = {
    #   description = "Prevent rclone restart during sleep";
    #   before = [ "sleep.target" ];
    #   wantedBy = [ "sleep.target" ];
      
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     ExecStart = "${pkgs.coreutils}/bin/touch /tmp/rclone-sleep-lock";
    #     ExecStop = "${pkgs.coreutils}/bin/rm -f /tmp/rclone-sleep-lock";
    #   };
    # };
    
  };
}
