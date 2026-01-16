# also need RCLONE_TEST in the onedrive?
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

    /*
      ----------------------------------------------------------
      1.  ROOT MOUNT SERVICE  (can actually do fusermount)
      ----------------------------------------------------------
    */
    systemd.services.rclone-mount = {
      description = "OneDrive rclone mount (system)";
      wantedBy = [ "multi-user.target" ];
      after = [ "my-network-online.service"];
      wants = [ "my-network-online.service"];
      requires = [ "my-network-online.service"];

      # Make it not prevent hibernating
      before = [ "sleep.target" ];

      preStart = ''
        # try to unmount any stale FUSE mount (use fuse3 fusermount)
        ${pkgs.fuse3}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
          /run/current-system/sw/bin/umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true

        # ensure mountpoint exists and owned by the right user
        ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.mountPoint}
        chown ${user}:users ${lib.escapeShellArg cfg.mountPoint}
        chmod 755 ${lib.escapeShellArg cfg.mountPoint}
      '';

      script = ''
        exec ${pkgs.rclone}/bin/rclone mount \
          ${lib.escapeShellArg cfg.remote} \
          ${lib.escapeShellArg cfg.mountPoint} \
          --vfs-cache-mode full \
          --vfs-cache-max-size 20G \
          --vfs-cache-max-age 168h \
          --vfs-cache-min-free-space 5G \
          --config ${home}/.config/rclone/rclone.conf \
      ''; # --log-level=DEBUG 
          # --no-check-certificate \
          # --disable-http2 \
          # --s3-no-check-bucket \
          # --s3-no-head-object \
      postStop = ''
        # Try clean FUSE unmount
        ${pkgs.fuse3}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
          /run/current-system/sw/bin/umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true

        # Kill any remaining rclone mount processes for this path
        ${pkgs.procps}/bin/pkill -f "rclone mount .* ${lib.escapeShellArg cfg.mountPoint}" || true
      '';

      serviceConfig = {
        Type = "notify";
        User = "yeshey";
        Group = "users";
        # RESTART POLICY - Progressive backoff for network changes
        Restart = "on-failure";
        RestartSec = "5s";
        RestartSteps = 8;
        RestartMaxDelaySec = "120s";  # Cap at 120s between retries
        
        # TIMEOUTS
        TimeoutStartSec = "60s";
        TimeoutStopSec = "20s";

        DeviceAllow = "/dev/fuse";
        CapabilityBoundingSet = "CAP_SYS_ADMIN";
        AmbientCapabilities = "CAP_SYS_ADMIN";

        # prevent stopping hibernation
        KillMode = "control-group"; 
        KillSignal = "SIGTERM";
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
