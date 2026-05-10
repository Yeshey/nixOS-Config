{
  flake.modules.homeManager.rclone-mount-onedrive =
    { lib, config, pkgs, ... }:
    let
      optName = "rclone-mount-onedrive";
      cfg = config.${optName};

      # Only the entries the user explicitly enabled
      enabledMounts = lib.filterAttrs (_: v: v.enable) cfg;

      mountSubmodule = lib.types.submodule {
        options = {
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
      };
    in
    {
      options.${optName} = lib.mkOption {
        type        = lib.types.attrsOf mountSubmodule;
        default     = {};
        description = "Attribute set of rclone OneDrive mounts, keyed by a name of your choice.";
      };

      config = lib.mkIf (enabledMounts != {}) {
        home.packages = with pkgs; [ rclone fuse3 ];

        # One activation entry per mount to create the parent directory
        home.activation = lib.mapAttrs' (name: mountCfg:
          lib.nameValuePair "createRcloneDirs-${name}" (
            lib.hm.dag.entryAfter ["writeBoundary"] ''
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf mountCfg.mountPoint)}
            ''
          )
        ) enabledMounts;

        # One systemd user service per mount
        systemd.user.services = lib.mapAttrs' (name: mountCfg:
          let svcName = "${optName}-${name}"; in
          lib.nameValuePair svcName {
            Unit = {
              Description = "rclone mount (user): ${mountCfg.remote} → ${mountCfg.mountPoint}";
              After  = [ "network-online.target" ];
              Wants  = [ "network-online.target" ];
              Before = [ "sleep.target" ];
            };

            Install.WantedBy = [ "default.target" ] ++ mountCfg.extraWantedBy;

            Service = {
              Type = "notify";

              ExecStartPre =
                let
                  preStartScript = pkgs.writeShellScript "${svcName}-pre" ''
                    ${pkgs.procps}/bin/pkill -x rclone || true
                    fusermount3 -uz ${lib.escapeShellArg mountCfg.mountPoint} 2>/dev/null || \
                      umount -l ${lib.escapeShellArg mountCfg.mountPoint} 2>/dev/null || true
                    ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg mountCfg.mountPoint}
                    ${pkgs.coreutils}/bin/chmod 755 ${lib.escapeShellArg mountCfg.mountPoint}
                  '';
                in "${preStartScript}";

              ExecStart =
                let
                  mountScript = pkgs.writeShellScript svcName ''
                    exec ${pkgs.rclone}/bin/rclone mount \
                      ${lib.escapeShellArg mountCfg.remote} \
                      ${lib.escapeShellArg mountCfg.mountPoint} \
                      --links \
                      --vfs-cache-mode full \
                      --vfs-cache-max-age 168h \
                      --vfs-cache-min-free-space 10G \
                      --vfs-cache-max-size 20G \
                      --disable-http2 \
                      --config ${config.home.homeDirectory}/.config/rclone/rclone.conf \
                      ${lib.optionalString mountCfg.allowOther "--allow-other"} \
                      ${lib.optionalString mountCfg.allowNonEmpty "--allow-non-empty"}
                  '';
                in "${mountScript}";

              ExecStopPost =
                let
                  postStopScript = pkgs.writeShellScript "${svcName}-post" ''
                    fusermount3 -uz ${lib.escapeShellArg mountCfg.mountPoint} 2>/dev/null || \
                      umount -l ${lib.escapeShellArg mountCfg.mountPoint} 2>/dev/null || true
                  '';
                in "${postStopScript}";

              Restart            = "on-failure";
              RestartSec         = "10s";
              RestartMaxDelaySec = "5min";
              RestartSteps       = "5";
              TimeoutStopSec     = "30s";
              KillMode           = "mixed";
            };
          }
        ) enabledMounts;
      };
    };

  flake.modules.nixos.rclone-mount-onedrive =
    { lib, config, pkgs, ... }:
    let
      optName = "rclone-mount-onedrive";
      cfg = config.${optName};

      enabledMounts = lib.filterAttrs (_: v: v.enable) cfg;

      mountSubmodule = lib.types.submodule {
        options = {
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
            default     = true;
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
      };
    in
    {
      options.${optName} = lib.mkOption {
        type        = lib.types.attrsOf mountSubmodule;
        default     = {};
        description = "Attribute set of rclone OneDrive mounts, keyed by a name of your choice.";
      };

      config = lib.mkIf (enabledMounts != {}) {
        environment.systemPackages = with pkgs; [ rclone fuse3 ];

        # Enable user_allow_other globally if any mount needs it
        programs.fuse.userAllowOther =
          lib.mkIf (lib.any (m: m.allowOther) (lib.attrValues enabledMounts)) true;

        systemd.services = lib.mapAttrs' (name: mountCfg:
          let svcName = "${optName}-${name}"; in
          lib.nameValuePair svcName {
            description = "rclone mount (system): ${mountCfg.remote} → ${mountCfg.mountPoint}";
            after    = [ "network-online.target" ];
            wants    = [ "network-online.target" ];
            before   = [ "sleep.target" "remote-fs.target" "multi-user.target" ] ++ mountCfg.extraWantedBy;
            wantedBy = [ "remote-fs.target" "multi-user.target" ] ++ mountCfg.extraWantedBy;

            serviceConfig = {
              Type        = "notify";
              NotifyAccess = "all";

              ExecStartPre =
                let
                  preStartScript = pkgs.writeShellScript "${svcName}-pre" ''
                    ${pkgs.procps}/bin/pkill -f "rclone mount ${mountCfg.remote}" || true
                    ${pkgs.fuse3}/bin/fusermount3 -uz ${lib.escapeShellArg mountCfg.mountPoint} 2>/dev/null || \
                      ${pkgs.util-linux}/bin/umount -l ${lib.escapeShellArg mountCfg.mountPoint} 2>/dev/null || true
                    ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg mountCfg.mountPoint}
                    ${pkgs.coreutils}/bin/chmod 755 ${lib.escapeShellArg mountCfg.mountPoint}
                  '';
                in "${preStartScript}";

              ExecStart =
                let
                  mountScript = pkgs.writeShellScript svcName ''
                    exec ${pkgs.rclone}/bin/rclone mount \
                      ${lib.escapeShellArg mountCfg.remote} \
                      ${lib.escapeShellArg mountCfg.mountPoint} \
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
                      ${lib.optionalString mountCfg.allowOther "--allow-other"} \
                      ${lib.optionalString mountCfg.allowNonEmpty "--allow-non-empty"}
                  '';
                in "${mountScript}";

              ExecStopPost =
                let
                  postStopScript = pkgs.writeShellScript "${svcName}-post" ''
                    ${pkgs.fuse3}/bin/fusermount3 -uz ${lib.escapeShellArg mountCfg.mountPoint} 2>/dev/null || \
                      ${pkgs.util-linux}/bin/umount -l ${lib.escapeShellArg mountCfg.mountPoint} 2>/dev/null || true
                  '';
                in "${postStopScript}";

              Restart            = "on-failure";
              RestartSec         = "10s";
              RestartMaxDelaySec = "5min";
              RestartSteps       = 5;
              TimeoutStopSec     = "30s";
              KillMode           = "mixed";
            };
          }
        ) enabledMounts;
      };
    };
}