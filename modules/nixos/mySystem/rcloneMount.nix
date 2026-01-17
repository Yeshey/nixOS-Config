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

      # Make it not prevent hibernating
      before = [ "sleep.target" ];

      preStart = ''
        ${pkgs.procps}/bin/pkill -u ${user} -x rclone || true

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
          --links \
          --config ${home}/.config/rclone/rclone.conf \
          --allow-other
      ''; # So, the only bad thing happening right now is that if it is in the middle of opperations and you try hibernating, it will not work. And if it doesn't finish uploading when you poweroff, when it boots up again, the mount won't appear until it finishes uploading the things from last time.
          # --buffer-size 512M \ # --vfs-cache is finnicky sometimes! if you remove it put this in its place
          # --log-level=DEBUG 
          # --no-check-certificate \
          # --disable-http2 \
          # --s3-no-check-bucket \
          # --s3-no-head-object \
          # --vfs-cache-mode full \
          # --vfs-cache-max-size 30G \
          # --vfs-cache-max-age 1h0m0s \
          # --vfs-cache-min-free-space 5G \
          # --no-seek \
          # --bind 0.0.0.0 \
          # --timeout 10s \


      # All stop/cleanup logic in postStop (declared-style Nix)
      postStop = ''
        # try regular fusermount first, fallback to lazy umount
        ${pkgs.fuse3}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
          /run/current-system/sw/bin/umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
      '';
      # # kill any stray rclone processes that still reference the mountpoint
      # ${pkgs.procps}/bin/pkill -f "rclone mount .* ${lib.escapeShellArg cfg.mountPoint}" || true
      # # brief pause & another unmount attempt to ensure kernel releases the endpoint
      # sleep 1
      # ${pkgs.fuse3}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true

      unitConfig = {
        AssertPathIsDirectory = cfg.mountPoint;
        
        # limit restart burst so we don't hammer everything during network storms
        StartLimitIntervalSec = 100; 
        StartLimitBurst = 10;
      };

      serviceConfig = {
        Type = "simple";
        User = user;
        Group = "users";

        Restart = "on-failure";
        RestartSec = "10s";

        TimeoutStopSec = "100s";
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
          
          # 1. LOGGING (So we know why it ran or didn't run)
          log() { logger -t "rclone-dispatcher" "$1"; }

          # 2. SLEEP CHECK
          # Check if the system is currently executing a sleep/suspend/hibernate job.
          # 'systemctl is-system-running' is sometimes too slow to update.
          # We check if sleep.target is active or if the shutdown target is active.
          if systemctl is-active --quiet sleep.target || \
             systemctl is-active --quiet suspend.target || \
             systemctl is-active --quiet hibernate.target || \
             systemctl is-active --quiet suspend-then-hibernate.target || \
             systemctl is-active --quiet hybrid-sleep.target; then
             log "System is sleeping/hibernating. Ignoring event $ACTION."
             exit 0
          fi

          # 3. ACTION HANDLER
          case "$ACTION" in
            # or let rclone wait. Restarting on down causes hibernation races.
            up|vpn-up|vpn-down)
              log "Network/VPN UP ($ACTION). Restarting rclone mount..."
              systemctl restart rclone-mount.service
              ;;
            *)
              # Ignore down, vpn-down, pre-up, etc.
              ;;
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
