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

    /*
      ----------------------------------------------------------
      1.  ROOT MOUNT SERVICE  (can actually do fusermount)
      ----------------------------------------------------------
    */
    systemd.services.rclone-mount = {
      description = "OneDrive rclone mount (system)";
      wantedBy = [ "multi-user.target" ];
      after = [ "my-network-online.service" ];
      wants = [ "my-network-online.service" ];
      requires = [ "my-network-online.service" ];

      # Make it not prevent hibernating
      before = [ "sleep.target" ];

      preStart = ''
        # try clean unmount (fuse3 fusermount)
        ${pkgs.fuse3}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
          /run/current-system/sw/bin/umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true

        ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.mountPoint}
        chown ${user}:users ${lib.escapeShellArg cfg.mountPoint}
        chmod 755 ${lib.escapeShellArg cfg.mountPoint}
      '';

      script = ''
        exec ${pkgs.rclone}/bin/rclone mount \
          ${lib.escapeShellArg cfg.remote} \
          ${lib.escapeShellArg cfg.mountPoint} \
          --vfs-cache-mode full \
          --vfs-cache-max-size 30G \
          --vfs-cache-max-age 168h \
          --config ${home}/.config/rclone/rclone.conf \
          --allow-other
      ''; # --log-level=DEBUG 
          # --no-check-certificate \
          # --disable-http2 \
          # --s3-no-check-bucket \
          # --s3-no-head-object \

      # All stop/cleanup logic in postStop (declared-style Nix)
      postStop = ''
        # try regular fusermount first, fallback to lazy umount
        ${pkgs.fuse3}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
          /run/current-system/sw/bin/umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true

        # kill any stray rclone processes that still reference the mountpoint
        ${pkgs.procps}/bin/pkill -f "rclone mount .* ${lib.escapeShellArg cfg.mountPoint}" || true

        # brief pause & another unmount attempt to ensure kernel releases the endpoint
        sleep 1
        ${pkgs.fuse3}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
      '';

      serviceConfig = {
        Type = "simple";
        User = user;
        Group = "users";

        Restart = "on-failure";
        RestartSec = "10s";

        TimeoutStartSec = "60s";
        TimeoutStopSec = "60s";
        KillMode = "control-group";
        KillSignal = "SIGTERM";

        DeviceAllow = "/dev/fuse";
        CapabilityBoundingSet = "CAP_SYS_ADMIN";
        AmbientCapabilities = "CAP_SYS_ADMIN";

        # limit restart burst so we don't hammer everything during network storms
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
    };


    # Make it so every time there is a Network change the rclone mount restarts
    environment.etc."NetworkManager/dispatcher.d/50-rclone-restart".text = ''
      #!/bin/sh
      ACTION="$2"
      case "$ACTION" in
        up|down|vpn-up|vpn-down|connectivity-change|dhcp4-change|dhcp6-change)
          /run/current-system/sw/bin/systemctl restart --no-block rclone-mount.service
          ;;
      esac
    '';
    environment.etc."NetworkManager/dispatcher.d/50-rclone-restart".mode = "0755";
    
  };
}
