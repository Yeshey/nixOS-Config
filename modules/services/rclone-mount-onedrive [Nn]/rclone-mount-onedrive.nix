# Even made a askubuntu post: https://askubuntu.com/a/1563171/986310
{
  flake.modules.homeManager.rclone-mount-onedrive =
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
          default     = false;
          description = "If true, add --allow-other to rclone mount (requires user_allow_other in /etc/fuse.conf).";
        };

        allowNonEmpty = lib.mkOption {
          type        = lib.types.bool;
          default     = true;
          description = ''
            If true, add --allow-non-empty so rclone can mount even if the mount point
            directory is not empty (e.g. contains stale local files from a previous
            failed unmount). The local contents are hidden by the overlay while mounted.
          '';
        };

        extraWantedBy = lib.mkOption {
          type        = lib.types.listOf lib.types.str;
          default     = [];
          description = ''
            Additional systemd targets that should pull in this mount, on top of
            the always-present "remote-fs.target". For example, add
            "graphical-session.target" if your desktop session needs an explicit
            dependency on the mount.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [ rclone fuse3 ];

        # Create parent directory during activation (before services start)
        home.activation.createRcloneDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf cfg.mountPoint)}
        '';

        # Use systemctl --user status rclone-mount-onedrive
        systemd.user.services.${optName} = {
          Unit = {
            Description = "rclone mount (user): ${cfg.remote} → ${cfg.mountPoint}";
            After  = [ "network-online.target" ];
            Wants  = [ "network-online.target" ];
            Before = [ "sleep.target" ];
          };

          Install.WantedBy = [ "default.target" ] ++ cfg.extraWantedBy;

          Service = {
            Type = "notify";

            ExecStartPre =
              let
                preStartScript = pkgs.writeShellScript "${optName}-pre" ''
                  # Kill any existing rclone processes
                  ${pkgs.procps}/bin/pkill -x rclone || true

                  # Try clean unmount
                  fusermount3 -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
                    umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true

                  # Ensure mount point exists and is a directory
                  ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.mountPoint}
                  chmod 755 ${lib.escapeShellArg cfg.mountPoint}
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
                    --disable-http2 \
                    --config ${config.home.homeDirectory}/.config/rclone/rclone.conf \
                    ${lib.optionalString cfg.allowOther "--allow-other"} \
                    ${lib.optionalString cfg.allowNonEmpty "--allow-non-empty"}
                '';
              in "${mountScript}";

            ExecStopPost =
              let
                postStopScript = pkgs.writeShellScript "${optName}-post" ''
                  fusermount3 -uz ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || \
                    umount -l ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
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

        allowNonEmpty = lib.mkOption {
          type        = lib.types.bool;
          default     = true;
          description = ''
            If true, add --allow-non-empty so rclone can mount even if the mount point
            directory is not empty (e.g. contains stale local files from a previous
            failed unmount). The local contents are hidden by the overlay while mounted.
          '';
        };

        extraWantedBy = lib.mkOption {
          type        = lib.types.listOf lib.types.str;
          default     = [];
          description = ''
            Additional systemd targets that should pull in this mount, on top of
            the always-present "remote-fs.target". The system will still boot if
            the mount fails (Restart=on-failure, not required).
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [ rclone fuse3 ];

        # Automatically add user_allow_other to /etc/fuse.conf
        programs.fuse.userAllowOther = lib.mkIf cfg.allowOther true;

        systemd.services.${optName} = {
          description = "rclone mount (system): ${cfg.remote} → ${cfg.mountPoint}";
          after    = [ "network-online.target" ];
          wants    = [ "network-online.target" ];
          before   = [ "sleep.target" "remote-fs.target" "multi-user.target" ] ++ cfg.extraWantedBy;
          wantedBy = [ "remote-fs.target" "multi-user.target" ] ++ cfg.extraWantedBy;

          serviceConfig = {
            Type = "notify";
            NotifyAccess = "all";  # Allow rclone to send notify signals

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
                    --dir-cache-time 2h \
                    --disable-http2 \
                    --config /root/.config/rclone/rclone.conf \
                    --vfs-read-chunk-size 8M \
                    --vfs-read-chunk-size-limit 64M \
                    --transfers 2 \
                    --tpslimit 6 \
                    --tpslimit-burst 10 \
                    ${lib.optionalString cfg.allowOther "--allow-other"} \
                    ${lib.optionalString cfg.allowNonEmpty "--allow-non-empty"}
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