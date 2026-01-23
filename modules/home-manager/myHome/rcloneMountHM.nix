{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.rcloneMountHM;
  home = config.home.homeDirectory;
  user = config.home.username;
in
{
  options.myHome.rcloneMountHM = with lib; {
    enable = mkEnableOption "rcloneMountHM";

    mountPoint = mkOption {
      type = types.str;
      default = "${home}/OneDrive/ISCTE";
      description = "Path where the rclone remote will be mounted.";
    };

    remote = mkOption {
      type = types.str;
      default = "OneDriveISCTE:";
      description = "rclone remote/remote-path (eg. 'onedrive:' or 'onedrive:SomeFolder').";
    };

    allowOther = mkOption {
      type = types.bool;
      default = false;
      description = "If true, add --allow-other to rclone mount (requires user_allow_other in /etc/fuse.conf).";
    };
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

    home.packages = with pkgs; [
      rclone
      fuse3
    ];

    # Create parent directory during activation (before services start)
    home.activation.createRcloneDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf cfg.mountPoint)}
    '';

    # Use systemctl --user status rclone-mount
    systemd.user.services.rclone-mount = {
      Unit = {
        Description = "OneDrive rclone mount (user)";
        After = [ "network-online.target" "my-network-online" ];
        Wants = [ "network-online.target" "my-network-online" ];
        Before = [ "sleep.target" ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Type = "notify";
        
        ExecStartPre = let
          preStartScript = pkgs.writeShellScript "rclone-mount-pre" ''
            # Kill any existing rclone processes
            ${pkgs.procps}/bin/pkill -x rclone || true
            
            # try clean unmount
            fusermount3 -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
              umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true

            # Ensure mount point exists and is a directory
            ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.mountPoint}
            chmod 755 ${lib.escapeShellArg cfg.mountPoint}
          '';
        in "${preStartScript}";

        ExecStart = let
          mountScript = pkgs.writeShellScript "rclone-mount" ''
            exec ${pkgs.rclone}/bin/rclone mount \
              ${lib.escapeShellArg cfg.remote} \
              ${lib.escapeShellArg cfg.mountPoint} \
              --links \
              --vfs-cache-mode full \
              --config ${home}/.config/rclone/rclone.conf \
              ${lib.optionalString cfg.allowOther "--allow-other"}
          '';
        in "${mountScript}"; # --allow-non-empty \ so it can mount anyways if it becomes unresponsive when you restart it

        ExecStopPost = let
          postStopScript = pkgs.writeShellScript "rclone-mount-post" ''
            # try regular fusermount first, fallback to lazy umount
            fusermount3 -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
              umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
          '';
        in "${postStopScript}";

        Restart = "on-failure";
        RestartSec = "10s";
        RestartMaxDelaySec = "5min";
        RestartSteps = "5"; # Steps: 10s → 20s → 40s → 80s → 160s → 5min → 5min → ...
        
        TimeoutStopSec = "30s";
        KillMode = "mixed";
      };
    };

    # This runs a server on localhost instead that you can access on nautilus with dav://localhost:8080. But it's not as fast or good
    # systemd.user.services.rclone-webdav = {
    #   Service = {
    #     ExecStart = "${pkgs.rclone}/bin/rclone serve webdav OneDriveISCTE:";
    #     Restart = "on-failure";
    #   };
    # };

  };
}