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
      #default = "/home/yeshey/OneDriveISCTE";
      #default = "/mnt/OneDrive/ISCTE"; # DON'T CHANGE!
      default = "${home}/OneDrive/ISCTE"; # DON'T CHANGE!
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

    systemd.tmpfiles.rules = [
      "d ${home}/OneDrive 0755 ${user} users -"
      "d '${cfg.mountPoint}' 0755 ${user} users -"
    ];

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
          --vfs-cache-max-age 1h0m0s \
          --vfs-cache-min-free-space 5G \
          --no-seek \
          --bind 0.0.0.0 \
          --timeout 10s \
          --cache-db-purge \
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

      unitConfig = {
        AssertPathIsDirectory = cfg.mountPoint;
        
        # limit restart burst so we don't hammer everything during network storms
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };

      serviceConfig = {
        Type = "simple";
        User = user;
        Group = "users";

        Restart = "on-failure";
        RestartSec = "10s";

        TimeoutStartSec = "60s";
        TimeoutStopSec = "60s";
        KillMode = "mixed";

        DeviceAllow = "/dev/fuse";
        CapabilityBoundingSet = "CAP_SYS_ADMIN";
        AmbientCapabilities = "CAP_SYS_ADMIN";
      };
    };

    # Restarts the mount when there is a network change for it to not die, with special logic to not prevent hibernating.
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeText "rclone-restart-hook" ''
          #!/bin/sh
          ACTION="$2"
          
          # Safety check: Don't run if system is shutting down or sleeping
          if [ "$(systemctl is-system-running)" != "running" ]; then
            exit 0
          fi

          case "$ACTION" in
            # Only restart on UP events (Connection established / VPN change)
            up|vpn-up|vpn-down)
              logger -t "rclone-dispatcher" "Network/VPN UP. Restarting rclone mount..."
              systemctl try-restart rclone-mount.service
              ;;
            # We explicitly ignore 'down' events to prevent fighting with Hibernate
          esac
        '';
      }
    ];

    # If still hanging with trackerfiles maybe uncomment this
    # # 3. THE WATCHDOG SERVICE (Resource usage is negligible)
    # systemd.services.rclone-healthcheck = {
    #   description = "Restart rclone if mount is frozen";
    #   serviceConfig = {
    #     Type = "oneshot";
    #     User = "root";
    #     ExecStart = pkgs.writeShellScript "rclone-check" ''
    #       if systemctl is-active --quiet rclone-mount.service; then
    #         # If 'ls' takes more than 5 seconds, the mount is dead.
    #         if ! ${pkgs.coreutils}/bin/timeout 5s ${pkgs.coreutils}/bin/ls -1q ${lib.escapeShellArg cfg.mountPoint} >/dev/null 2>&1; then
    #           echo "Healthcheck: Mount unresponsive. Restarting..."
    #           systemctl restart rclone-mount.service
    #         fi
    #       fi
    #     '';
    #   };
    # };

    # # 4. THE TIMER (Runs check every 60s)
    # systemd.timers.rclone-healthcheck = {
    #   description = "Run rclone health check every minute";
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnBootSec = "5m"; # Give it time to start initially
    #     OnUnitActiveSec = "1m";
    #   };
    # };

    
  };
}
