# restore with:
# sudo -E \
#   RESTIC_REPOSITORY="rclone:OneDriveISCTE:ResticBackups/servers" \
#   RESTIC_PASSWORD="123456789" \
#   RCLONE_CONFIG="/home/yeshey/.config/rclone/rclone.conf" \
#   restic restore latest \
#     --target / \
#     --include "/home/yeshey" \
#     --verbose
{ ... }: # TODO impermanence
let
  # Shared option definitions for both nixos and homeManager modules
  jobOptions = lib: {
    enable           = lib.mkEnableOption "this backup job";
    paths            = lib.mkOption { type = lib.types.listOf lib.types.str; };
    rcloneRemoteName = lib.mkOption { type = lib.types.str; };
    rcloneRemotePath = lib.mkOption { type = lib.types.str; };
    passwordFile     = lib.mkOption { type = lib.types.path; };
    initialize       = lib.mkOption { type = lib.types.bool;  default = false; };
    startAt          = lib.mkOption { type = lib.types.str;   default = "*-*-* 14:00:00"; };
    randomizedDelaySec = lib.mkOption { type = lib.types.str; default = "5h"; };
    extraBackupArgs  = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
    exclude          = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
    prune.enable     = lib.mkOption { type = lib.types.bool;  default = true; };
    prune.keep = {
      within  = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
      daily   = lib.mkOption { type = lib.types.nullOr lib.types.int; default = 7; };
      weekly  = lib.mkOption { type = lib.types.nullOr lib.types.int; default = 4; };
      monthly = lib.mkOption { type = lib.types.nullOr lib.types.int; default = 12; };
      yearly  = lib.mkOption { type = lib.types.nullOr lib.types.int; default = null; };
    };
  };

  # nixos-only extra options
  jobOptionsNixos = lib: {
    user             = lib.mkOption { type = lib.types.str; };
    rcloneConfigFile = lib.mkOption { type = lib.types.path; };
  };

  # Shared job -> restic backup attrset converter (no rcloneConfigFile)
  mkBackup = pkgs: lib: job: {
    paths            = job.paths;
    repository       = "rclone:${job.rcloneRemoteName}:${job.rcloneRemotePath}";
    passwordFile     = job.passwordFile;
    initialize       = job.initialize;

    exclude = [
      "**/.cache"      "**/.git"         "**/node_modules"
      "**/Cache"       "**/_build"        "**/venv"
      "**/.venv"       "**/Steam"         "**/Trash"
      "**/.var/app/*/cache/" "**/.local/share/waydroid"
    ] ++ job.exclude;

    extraBackupArgs = [ "--verbose=1" ] ++ job.extraBackupArgs;

    pruneOpts = lib.optionals job.prune.enable (
      lib.filter (s: s != "") [
        (lib.optionalString (job.prune.keep.within  != null) "--keep-within ${job.prune.keep.within}")
        (lib.optionalString (job.prune.keep.daily   != null) "--keep-daily ${toString job.prune.keep.daily}")
        (lib.optionalString (job.prune.keep.weekly  != null) "--keep-weekly ${toString job.prune.keep.weekly}")
        (lib.optionalString (job.prune.keep.monthly != null) "--keep-monthly ${toString job.prune.keep.monthly}")
        (lib.optionalString (job.prune.keep.yearly  != null) "--keep-yearly ${toString job.prune.keep.yearly}")
      ]
    );

    timerConfig = {
      OnCalendar         = job.startAt;
      RandomizedDelaySec = job.randomizedDelaySec;
      Persistent         = true;
    };

    backupPrepareCommand = ''
      while ! ${pkgs.curl}/bin/curl --silent --max-time 5 https://1.0.0.1 > /dev/null 2>&1; do
        echo "Waiting for internet connection..."
        sleep 60
      done
      echo "Internet is up, let's upload ~raccoon memes~ some backups!"
    '';
  };
in
{
  flake.modules.nixos.restic-rclone-backups =
    { config, lib, pkgs, ... }:
    {
      options.restic-rclone-backups.jobs = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (lib.types.submodule {
          options = (jobOptions lib) // (jobOptionsNixos lib);
        });
      };

      config = lib.mkIf (config.restic-rclone-backups.jobs != { }) {
        services.restic.backups = lib.mapAttrs (jobName: job:
          lib.mkIf job.enable ((mkBackup pkgs lib job) // {
            user             = job.user;
            rcloneConfigFile = job.rcloneConfigFile;
          })
        ) config.restic-rclone-backups.jobs;

        systemd.services = lib.mapAttrs' (jobName: job:
          lib.nameValuePair "restic-backups-${jobName}" (lib.mkIf job.enable {
            serviceConfig = {
              Restart    = "on-failure";
              RestartSec = "15m";
            };
          })
        ) config.restic-rclone-backups.jobs;

        environment.systemPackages = with pkgs; [ rclone restic ];
      };
    };

  flake.modules.homeManager.restic-rclone-backups =
    { config, lib, pkgs, ... }:
    {
      options.restic-rclone-backups.jobs = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (lib.types.submodule {
          options = jobOptions lib;
        });
      };

      config =
        let
          enabledJobs = lib.filterAttrs (_: job: job.enable) config.restic-rclone-backups.jobs;
        in
        lib.mkIf (enabledJobs != { }) {
          services.restic.enable = true;
          services.restic.backups = lib.mapAttrs (_: job: mkBackup pkgs lib job) enabledJobs;

          home.packages = with pkgs; [ rclone restic ];
        };
    };
}