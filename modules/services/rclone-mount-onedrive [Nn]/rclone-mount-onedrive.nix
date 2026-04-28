# Even made a askubuntu post: https://askubuntu.com/a/1563171/986310
{
  flake.modules.homeManager.rclone-mount-onedrive =
    { lib, config, pkgs, ... }:
    let 
      optName = "rclone-mount-onedrive";
    in 
    {
      options.${optName} = {
        enable = lib.mkEnableOption "${optName}";

        mountPoint = lib.mkOption {
          type    = lib.types.str;
          description = "Path where the rclone remote will be mounted.";
        };

        remote = lib.mkOption {
          type    = lib.types.str;
          description = "rclone remote/remote-path (eg. 'onedrive:' or 'onedrive:SomeFolder').";
        };

        allowOther = lib.mkOption {
          type    = lib.types.bool;
          default = false;
          description = "If true, add --allow-other to rclone mount (requires user_allow_other in /etc/fuse.conf).";
        };
      };

      config = lib.mkIf config.${optName}.enable {
        home.packages = with pkgs; [ rclone fuse3 ];

        # Create parent directory during activation (before services start)
        home.activation.createRcloneDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf config.${optName}.mountPoint)}
        '';

        # Use systemctl --user status rclone-mount-onedrive
        systemd.user.services.${optName}= {
          Unit = {
            Description = "rclone mount (user): ${config.${optName}.remote} → ${config.${optName}.mountPoint}";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
            Before = [ "sleep.target" ];
          };

          Install.WantedBy = [ "default.target" ];

          Service = {
            Type = "notify";

            ExecStartPre =
              let
                preStartScript = pkgs.writeShellScript "${optName}-pre" ''
                  # Kill any existing rclone processes
                  ${pkgs.procps}/bin/pkill -x rclone || true

                  # try clean unmount
                  fusermount3 -uz ${lib.escapeShellArg config.${optName}.mountPoint} 2>/dev/null || \
                    umount -l ${lib.escapeShellArg config.${optName}.mountPoint} 2>/dev/null || true

                  # Ensure mount point exists and is a directory
                  ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg config.${optName}.mountPoint}
                  chmod 755 ${lib.escapeShellArg config.${optName}.mountPoint}
                '';
              in "${preStartScript}";

            ExecStart =
              let
                mountScript = pkgs.writeShellScript "${optName}" ''
                  exec ${pkgs.rclone}/bin/rclone mount \
                    ${lib.escapeShellArg config.${optName}.remote} \
                    ${lib.escapeShellArg config.${optName}.mountPoint} \
                    --links \
                    --vfs-cache-mode full \
                    --vfs-cache-max-age 168h \
                    --vfs-cache-min-free-space 10G \
                    --vfs-cache-max-size 20G \
                    --bwlimit 4M:off \
                    --disable-http2 \
                    --config ${config.home.homeDirectory}/.config/rclone/rclone.conf \
                    ${lib.optionalString config.${optName}.allowOther "--allow-other"}
                '';
                # Let's see if --bwlimit 4M:off limiting upload makes downloads more responsive
                # --allow-non-empty \ so it can mount anyways if it becomes unresponsive when you restart it
                # --debug-fuse \
                # -vv --log-file=/tmp/${optName}.log \
              in "${mountScript}";

            ExecStopPost =
              let
                postStopScript = pkgs.writeShellScript "${optName}-post" ''
                  # try regular fusermount first, fallback to lazy umount
                  fusermount3 -uz ${lib.escapeShellArg config.${optName}.mountPoint} 2>/dev/null || \
                    umount -l ${lib.escapeShellArg config.${optName}.mountPoint} 2>/dev/null || true
                '';
              in "${postStopScript}";

            Restart            = "on-failure";
            RestartSec         = "10s";
            RestartMaxDelaySec = "5min";
            RestartSteps       = "5"; # Steps: 10s → 20s → 40s → 80s → 160s → 5min → 5min → ...
            TimeoutStopSec     = "30s";
            KillMode           = "mixed";
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
    };

  flake.modules.nixos.rclone-mount-onedrive =
    { lib, config, pkgs, ... }:
    let 
      optName = "rclone-mount-onedrive";
      cfg = config.${optName};
    in 
    {
      options.${optName} = {
        enable = lib.mkEnableOption "${optName}";

        mountPoint = lib.mkOption {
          type        = lib.types.str;
          description = "Path where the rclone remote will be mounted.";
        };

        remote = lib.mkOption {
          type        = lib.types.str;
          description = "rclone remote/remote-path (eg. 'onedrive:' or 'onedrive:SomeFolder').";
        };

        allowOther = lib.mkOption {
          type        = lib.types.bool;
          default     = true; # Highly recommended for root mounts so your normal user can read it
          description = "If true, add --allow-other to rclone mount and enable it system-wide.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [ rclone fuse3 ];

        # Automatically add user_allow_other to /etc/fuse.conf
        programs.fuse.userAllowOther = lib.mkIf cfg.allowOther true;

        systemd.services.${optName} = {
          description = "rclone mount (system): ${cfg.remote} → ${cfg.mountPoint}";
          after    =[ "network-online.target" ];
          wants    = [ "network-online.target" ];
          before   =[ "sleep.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "notify";

            ExecStartPre =
              let
                preStartScript = pkgs.writeShellScript "${optName}-pre" ''
                  # Kill any existing rclone processes associated with this mount
                  ${pkgs.procps}/bin/pkill -f "rclone mount ${cfg.remote}" || true

                  # Try clean unmount
                  ${pkgs.fuse3}/bin/fusermount3 -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
                    ${pkgs.util-linux}/bin/umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true

                  # Ensure mount point exists and is a directory
                  ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.mountPoint}
                  ${pkgs.coreutils}/bin/chmod 755 ${lib.escapeShellArg cfg.mountPoint}
                '';
              in "${preStartScript}";

            ExecStart =
              let
                mountScript = pkgs.writeShellScript "${optName}" ''
                  exec ${pkgs.rclone}/bin/rclone mount \
                    ${lib.escapeShellArg cfg.remote} \
                    ${lib.escapeShellArg cfg.mountPoint} \
                    --links \
                    --vfs-cache-mode full \
                    --vfs-cache-max-age 168h \
                    --vfs-cache-min-free-space 10G \
                    --vfs-cache-max-size 20G \
                    --bwlimit 4M:off \
                    --disable-http2 \
                    --config /root/.config/rclone/rclone.conf \
                    ${lib.optionalString cfg.allowOther "--allow-other"}
                '';
              in "${mountScript}";

            ExecStopPost =
              let
                postStopScript = pkgs.writeShellScript "${optName}-post" ''
                  ${pkgs.fuse3}/bin/fusermount3 -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
                    ${pkgs.util-linux}/bin/umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
                '';
              in "${postStopScript}";

            Restart            = "on-failure";
            RestartSec         = "10s";
            RestartMaxDelaySec = "5min";
            RestartSteps       = 5;
            TimeoutStopSec     = "30s";
            KillMode           = "mixed";
          };
        };
      };
    };
}