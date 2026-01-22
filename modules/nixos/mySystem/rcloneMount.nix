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
      #default = "${home}/OneDrive/ISCTE"; # DON'T CHANGE!
      default = "/run/media/Onedrive";
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
      default = true;
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
#      "d ${home}/OneDrive 0755 ${user} users -"
#      "d '${cfg.mountPoint}' 0755 ${user} users -"
      "d '${cfg.mountPoint}' 0750 root root -"
    ];

    # --- systemd: rclone .mount (runs the actual rclone mount) ---
    # Note: NixOS translates the following into /etc/systemd/system/<escaped>.mount
    systemd.mounts = [
      {
        description = "rclone mount for ${cfg.remote} at ${cfg.mountPoint}";
        # 'what' is the rclone remote identifier (eg. "OneDriveISCTE:")
        what = cfg.remote;
        where = cfg.mountPoint;

        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        # Make it not prevent hibernating
        # before = [ "sleep.target" ];

        # filesystem type to pass as '-t' to mount; rclone examples use 'rclone'
        type = "rclone";

        # options passed as comma-separated: config=...,allow-other,...
        # build the list conditionally so we keep config and allow-other if requested
        options = lib.concatStringsSep "," (
          lib.filter (x: x != null) [
            "config=${home}/.config/rclone/rclone.conf"
            (if cfg.allowOther then "allow-other" else null)
            # optional:
            # "vfs-cache-mode=full"
          ]
        );

        # systemd unit-level directives for the mount unit
        unitConfig = {
          AssertPathIsDirectory = cfg.mountPoint;
          
          # limit restart burst so we don't hammer everything during network storms
          StartLimitIntervalSec = 100; 
          StartLimitBurst = 10;
        };

        # mount-specific options (these become members of [Mount])
        # If you need additional systemd mount timeouts, add them here:
        #mountConfig = {
          # example: "x-systemd.idle-timeout" can be defined in options instead
          # (left empty intentionally)
        #};
      }
    ];

    # --- systemd: automount to trigger on first access and auto-unmount after idle ---
    systemd.automounts = [
      {
        description = "automount ${cfg.mountPoint} (rclone) - on-demand";
        where = cfg.mountPoint;

        # by default we want the automount unit started at boot
        wantedBy = [ "multi-user.target" ];

        # Make it not prevent hibernating
        # before = [ "sleep.target" ];

        # # If you want the automount to unmount after, e.g., 10 minutes idle:
        # automountConfig = {
        #   # TimeoutIdleSec controls how long the mount stays active after last access
        #   TimeoutIdleSec = "1m";
        # };
      }
    ];

    # Restarts the mount when there is a network change for it to not die, with special logic to not prevent hibernating.
    # Maybeeee it would be good to remove this
    # networking.networkmanager.dispatcherScripts = [
    #   {
    #     type = "basic";
    #     source = pkgs.writeText "rclone-restart-hook" ''
    #       #!/bin/sh
    #       ACTION="$2"
          
    #       # 1. LOGGING (So we know why it ran or didn't run)
    #       log() { logger -t "rclone-dispatcher" "$1"; }

    #       # 2. SLEEP CHECK
    #       # Check if the system is currently executing a sleep/suspend/hibernate job.
    #       # 'systemctl is-system-running' is sometimes too slow to update.
    #       # We check if sleep.target is active or if the shutdown target is active.
    #       if systemctl is-active --quiet sleep.target || \
    #          systemctl is-active --quiet suspend.target || \
    #          systemctl is-active --quiet hibernate.target || \
    #          systemctl is-active --quiet suspend-then-hibernate.target || \
    #          systemctl is-active --quiet hybrid-sleep.target; then
    #          log "System is sleeping/hibernating. Ignoring event $ACTION."
    #          exit 0
    #       fi

    #       # 3. ACTION HANDLER
    #       case "$ACTION" in
    #         # or let rclone wait. Restarting on down causes hibernation races.
    #         up|vpn-up|vpn-down)
    #           log "Network/VPN ($ACTION). Restarting rclone mount..."
    #           systemctl restart --no-block rclone-mount.service
    #           ;;
    #         *)
    #           # Ignore down, vpn-down, pre-up, etc.
    #           ;;
    #       esac
    #     '';
    #   }
    # ];

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
