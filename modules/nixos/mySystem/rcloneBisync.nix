# also need RCLONE_TEST in the onedrive?
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

    /* ----------------------------------------------------------
       1.  ROOT MOUNT SERVICE  (can actually do fusermount)
       ---------------------------------------------------------- */
systemd.services.rclone-mount = {
  description = "OneDrive rclone mount (system)";
  wantedBy = [ "multi-user.target" ];
  after    = [ "network-online.target" ];
  wants    = [ "network-online.target" ];

  preStart = ''
    mkdir -p ${lib.escapeShellArg cfg.mountPoint}
    chown ${user}:users ${lib.escapeShellArg cfg.mountPoint}
    chmod 755 ${lib.escapeShellArg cfg.mountPoint}
    ${pkgs.fuse}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
  '';

  script = ''
    exec ${pkgs.rclone}/bin/rclone mount \
      ${lib.escapeShellArg cfg.remote} \
      ${lib.escapeShellArg cfg.mountPoint} \
      --vfs-cache-mode full \
      --vfs-cache-max-size 40G \
      --vfs-cache-max-age 168h \
      --allow-other \
      --config ${home}/.config/rclone/rclone.conf
  '';

  postStop = ''
    ${pkgs.fuse}/bin/fusermount -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
  '';

  serviceConfig = {
    Type        = "notify";
    Restart     = "on-failure";
    RestartSec  = "30s";
    TimeoutStartSec = "60s";
  };
};

    /* ----------------------------------------------------------
       2.  USER BISYNC SERVICE  (reads user config, needs mount)
       ---------------------------------------------------------- */
systemd.user.services.rclone-bisync = {
  description = "OneDrive bisync";

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
  
  serviceConfig.Type = "oneshot";
};

    /* ----------------------------------------------------------
       3.  USER TIMER  (unchanged)
       ---------------------------------------------------------- */
    systemd.user.timers.rclone-bisync = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec       = "2m";
        OnUnitActiveSec = cfg.bisyncInterval;
        Persistent      = true;
        Unit            = "rclone-bisync.service";
      };
    };

    /* ----------------------------------------------------------
       4.  allow user linger so timer runs when not logged in
       ---------------------------------------------------------- */
    users.users.${user}.linger = true;
  };
}