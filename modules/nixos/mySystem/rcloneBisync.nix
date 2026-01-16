# also need RCLONE_TEST in the onedrive?
{
  config,
  lib,
  pkgs,
  ...
}:

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
      default = "/home/yeshey/OneDriveISCTE";
      description = "Path where the rclone remote will be mounted. System boot will not fail if the underlying device is not present.";
    };

    remote = mkOption {
      type = types.str;
      default = "OneDriveISCTE:";
      description = "rclone remote/remote-path (eg. 'onedrive:' or 'onedrive:SomeFolder').";
    };

    localPath = mkOption {
      type = types.str;
      default = "/home/yeshey/.onedriveISCTE-sync";
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
        ${pkgs.coreutils}/bin/mkdir -p ${cfg.mountPoint}
        mkdir -p ${lib.escapeShellArg cfg.mountPoint}
        chown ${user}:users ${lib.escapeShellArg cfg.mountPoint}
        chmod 755 ${lib.escapeShellArg cfg.mountPoint}
        ${pkgs.fuse}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint}update 2>/dev/null || true
      '';

      script = ''
        exec ${pkgs.rclone}/bin/rclone mount \
          ${lib.escapeShellArg cfg.remote} \
          ${lib.escapeShellArg cfg.mountPoint} \
          --vfs-cache-mode full \
          --vfs-cache-max-size 40G \
          --vfs-cache-max-age 168h \
          --config ${home}/.config/rclone/rclone.conf
      '';

      postStop = ''
        ${pkgs.fuse}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
      '';

      serviceConfig = {
        Type = "notify";
        User = "yeshey";
        Group = "users";
        Restart = "on-failure";
        RestartSec = "30s";
        TimeoutStartSec = "60s";

        DeviceAllow = "/dev/fuse";
        CapabilityBoundingSet = "CAP_SYS_ADMIN";
        AmbientCapabilities = "CAP_SYS_ADMIN";

        # prevent stopping hibernation
        KillMode = "control-group"; 
        KillSignal = "SIGTERM";
        TimeoutStopSec = "30s";
      };
    };

    /*
      ----------------------------------------------------------
      2.  USER BISYNC SERVICE  (reads user config, needs mount)
      ----------------------------------------------------------
    */
    # Change from systemd.user.services to systemd.services
    systemd.services.rclone-bisync = {
      description = "OneDrive bisync";
      
      # Now you can properly depend on the mount!
      after = [ "rclone-mount.service" ];
      requires = [ "rclone-mount.service" ];
      
      script = ''
        exec ${pkgs.rclone}/bin/rclone bisync \
          ${lib.escapeShellArg cfg.localPath} \
          ${lib.escapeShellArg cfg.remote} \
          --check-access \
          --compare size,modtime \
          --resilient \
          --recover \
          --max-lock 2m \
          --conflict-resolve newer \
          --create-empty-src-dirs \
          --verbose \
          --config ${home}/.config/rclone/rclone.conf \
          ${lib.optionalString cfg.firstRun "--resync"}
      '';
      
      serviceConfig = {
        Type = "oneshot";
        User = user;        # Run as your user
        Group = "users";

        Restart = "on-failure";
        RestartSec = "5s";
      };
      unitConfig = {
        StartLimitBurst = 3;
        StartLimitIntervalSec = "20s";
      };
    };

    # Change from systemd.user.timers to systemd.timers
    systemd.timers.rclone-bisync = {
      wantedBy = [ "timers.target" ];
      after = [ "rclone-mount.service" ];  # Timer also waits for mount
      
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = cfg.bisyncInterval;
        Persistent = true;
        Unit = "rclone-bisync.service";
      };
    };
    
  };
}
