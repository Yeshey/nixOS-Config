# restore with
# sudo -E \                                                                                                                                                                                                                    17:23:28
#   RESTIC_REPOSITORY="rclone:OneDriveISCTE:ResticBackups/servers" \
#   RESTIC_PASSWORD="123456789" \
#   RCLONE_CONFIG="/home/yeshey/.config/rclone/rclone.conf" \
#   restic restore 1fc528f5 \
#     --target / \
#     --include "/var/*" \
#     --include "/opt/*" \
#     --include "/srv/*" \
#     --overwrite always \
#     --verbose
# you'll have to chown, check https://github.com/restic/restic/pull/5449

# Filename: e.g., modules/nixos/mySystem/resticRcloneBackups.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.resticRcloneBackups;
  primaryUser = config.users.primaryUser.name;
in
{
  options.mySystem.resticRcloneBackups = with lib; {
    jobs = mkOption {
      type = types.attrsOf (types.submodule ({ name, config, ... }: {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this specific Restic+Rclone backup job is enabled.";
          };

          user = mkOption {
            type = types.str;
            default = primaryUser;
            description = "User to run the Restic backup as. This user needs read access to paths, rclone.conf, and passwordFile.";
          };

          paths = mkOption {
            type = types.listOf types.str;
            description = "List of absolute paths to back up.";
            example = [ "/home/${primaryUser}" "/srv/data" ];
          };

          rcloneRemoteName = mkOption {
            type = types.str;
            description = ''
              Name of the Rclone remote as configured in your rclone.conf file.
              Example: "myOneDrive"
            '';
            example = "onedrive-backup";
          };

          rcloneRemotePath = mkOption {
            type = types.str;
            description = ''
              Path within the Rclone remote where the Restic repository is (or will be) located.
              Example: "restic_backups/my_server"
            '';
            example = "restic/my-server-backups";
          };

          rcloneConfigFile = mkOption {
            type = types.path; # Use types.path for better validation
            description = ''
              Absolute path to the rclone.conf file.
              This file contains sensitive credentials. Ensure it's secured and readable by the specified 'user'.
              You can set up Rclone by running 'rclone config' as the intended backup user.
              Then, ensure this path points to that generated config file.
              For example, if 'user' is 'backupuser', run 'sudo -u backupuser rclone config'.
              The default rclone config path is '~/.config/rclone/rclone.conf'.
            '';
            example = "/var/lib/secrets/rclone/config.conf"; # Example using a system-wide managed secret
          };

          passwordFile = mkOption {
            type = types.path; # Use types.path
            description = ''
              Absolute path to the file containing the Restic repository password.
              This file is sensitive. Ensure it's secured and readable by the specified 'user'.
              If the repository is new and 'initialize' is true, this password will be used to create it.
            '';
            example = "/var/lib/secrets/restic/main-password";
          };

          initialize = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to run 'restic init' if the repository does not exist during the first backup attempt.";
          };

          startAt = mkOption {
            type = types.str;
            default = "*-*-* 14:00:00"; # Sets the default to 2 PM daily
            description = "When to trigger the backup (systemd OnCalendar= string).";
            example = "*-*-* 02:00:00";
          };

          randomizedDelaySec = mkOption {
            # Allow string or integer for flexibility, systemd handles it
            type = types.nullOr (types.either types.str types.int);
            default = "5h";
            description = "Randomized delay (in seconds or systemd time span string) for the backup timer to spread load.";
            example = "1h";
          };

          prune = {
            keep = {
              within = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Keep all archives within this duration from now (e.g., '7d', '2m', '1y'). Uses Restic's --keep-within.";
                example = "30d";
              };
              hourly = mkOption { # Added hourly
                type = types.nullOr types.int;
                default = null;
                description = "Number of hourly archives to keep. Uses Restic's --keep-hourly.";
              };
              daily = mkOption {
                type = types.nullOr types.int;
                default = 7; # Restic's default
                description = "Number of daily archives to keep. Uses Restic's --keep-daily.";
              };
              weekly = mkOption {
                type = types.nullOr types.int;
                default = 4; # Restic's default
                description = "Number of weekly archives to keep. Uses Restic's --keep-weekly.";
              };
              monthly = mkOption {
                type = types.nullOr types.int;
                default = 12; # Restic's default
                description = "Number of monthly archives to keep. Uses Restic's --keep-monthly.";
              };
              yearly = mkOption {
                type = types.nullOr types.int;
                default = null; # Restic default is "always" (or a very large number like 75)
                description = "Number of yearly archives to keep. Uses Restic's --keep-yearly.";
              };
            };
            # Option to enable automatic pruning after each backup.
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to automatically run 'restic forget --prune' after each successful backup, using the specified 'keep' options.";
            };
          };

          exclude = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of patterns to exclude from the backup (passed as --exclude flags).";
            example = [ "*/.cache" "**/*.tmp" ];
          };

          noCache = mkOption {
            type = types.bool;
            default = false;
            description = "If true, pass --no-cache to restic. Generally NOT recommended for cloud remotes due to performance implications.";
          };

          extraBackupArgs = mkOption {
            type = types.listOf types.str;
            default = [ "--verbose=1" ]; # Add some default verbosity
            description = "Extra arguments passed directly to 'restic backup'.";
            example = [ "--verbose=2" "--compression=max" ];
          };

          extraForgetArgs = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Extra arguments passed directly to 'restic forget' (e.g., for grouping).";
            example = [ "--group-by host,paths" ];
          };

          extraRcloneOpts = mkOption {
            type = types.nullOr (types.attrsOf (types.either types.str types.bool)); # MATCHES services.restic
            default = null;
            description = ''
              Attribute set of Rclone options. Keys are option names (without leading '--'),
              values are strings or booleans.
              Example: { bwlimit = "10M"; "drive-use-trash" = true; }
            '';
            example = { "onedrive-chunk-size" = "50M"; bwlimit = "10M"; };
          };

          environmentFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = ''
              Optional path to an environment file. Variables from this file will be sourced
              before running Restic. Useful for RESTIC_PASSWORD or Rclone environment variables.
              If RESTIC_PASSWORD is set here, `passwordFile` can be omitted (but ensure this file is secure).
            '';
          };

        };
      }));
      default = {};
      description = ''
        Defines Restic backup jobs that use Rclone as a backend.

        **Initial Rclone Setup (Manual Steps Required):**
        1. Ensure 'rclone' is installed on your system for configuration (e.g., `nix-env -iA nixos.rclone`).
        2. Run `rclone config` as the user who will perform the backups (specified in the 'user' option for the job).
           This will guide you through setting up your remote (e.g., OneDrive, Google Drive, S3).
           Give your remote a memorable name (e.g., "myOneDriveBackup").
        3. Note the path to the generated `rclone.conf` file (usually `~/.config/rclone/rclone.conf`).
           You will need to provide this path to the `rcloneConfigFile` option.
           It's recommended to move this file to a secure, root-readable location if backups run as root
           (e.g., `/var/lib/secrets/rclone.conf`) and manage its permissions carefully or use sops-nix.
        4. Create a Restic password and store it securely in a file. Provide this path to `passwordFile`.
           Example: `openssl rand -base64 32 > /var/lib/secrets/restic-main-password && chmod 400 /var/lib/secrets/restic-main-password`
      '';
    };
  };

  config = lib.mkIf (cfg.jobs != {}) {
    services.restic.backups = lib.mapAttrs' (jobName: jobCfg:
      lib.nameValuePair jobName (
        lib.mkIf jobCfg.enable {
          user = jobCfg.user;
          paths = jobCfg.paths;
          repository = "rclone:${jobCfg.rcloneRemoteName}:${jobCfg.rcloneRemotePath}";
          passwordFile = jobCfg.passwordFile; # Still required by services.restic.backups, but user can point to an empty file if RESTIC_PASSWORD is in environmentFile
          environmentFile = jobCfg.environmentFile;
          initialize = jobCfg.initialize;
          exclude = [
              # --- MODULE'S DEFAULT EXCLUDES START ---
              #  ** matches anything including paths `/`
              #  *  matches anything except paths `/`
              "**/.cache"
              "**/Downloads"
              "**/.direnv"
              "**/node_modules"
              "**/.git"
              "**/cache2"
              "**/Cache"
              "**/.config/Slack/logs"
              "**/.config/Code/CachedData"
              "**/.container-diff"
              "**/.npm/_cacache"
              "**/bower_components"
              "**/_build"
              "**/.tox"
              "**/venv"
              "**/.venv"
              "**/*cache*/"
              "**/Android"
              "**/.gradle"
              "**/.var/app/*/cache/" # faltpak
              "**/.cabal"
              "**/.vscode"
              "**/.stremio-server"
              "**/grapejuice"
              "**/baloo"
              "**/share/containers"
              "**/share/waydroid"
              "**/lutris"
              "**/Steam"
              # ".config" # Still recommend against this as a default, be more specific
              "**/.config/chromium"
              "**/.config/google-chrome"
              "**/.config/mozilla/firefox/*/cache2"
              "**/Trash"
              # --- YOUR MODULE'S DEFAULT EXCLUDES END ---
            ] ++ jobCfg.exclude; # jobCfg.exclude now comes from the user's configuration of your module

          rcloneConfigFile = jobCfg.rcloneConfigFile;
          rcloneOptions = jobCfg.extraRcloneOpts; # Now this directly passes the attribute set

          extraBackupArgs = jobCfg.extraBackupArgs ++ (lib.optional jobCfg.noCache "--no-cache");

          timerConfig = {
            OnCalendar = jobCfg.startAt;
            RandomizedDelaySec = lib.mkIf (jobCfg.randomizedDelaySec != null) (toString jobCfg.randomizedDelaySec);
            Persistent = true;
          };

          backupPrepareCommand = ''
            while ! /run/current-system/sw/bin/ping -c 1 1.0.0.1; do
              echo "Waiting for internet connection..."
              sleep 60
            done

            echo "Internet is up, let's upload ~raccoon memes~ some backups!"
          '';

          # Construct pruneOpts only if prune is enabled for this job
          pruneOpts = lib.mkIf jobCfg.prune.enable (
            let keep = jobCfg.prune.keep;
            in lib.filter (x: x != null && x != "") (
              [
                (lib.optionalString (keep.within != null) "--keep-within ${keep.within}")
                (lib.optionalString (keep.hourly != null) "--keep-hourly ${toString keep.hourly}")
                (lib.optionalString (keep.daily != null) "--keep-daily ${toString keep.daily}")
                (lib.optionalString (keep.weekly != null) "--keep-weekly ${toString keep.weekly}")
                (lib.optionalString (keep.monthly != null) "--keep-monthly ${toString keep.monthly}")
                (lib.optionalString (keep.yearly != null) "--keep-yearly ${toString keep.yearly}")
              ] ++ jobCfg.extraForgetArgs # Add any extra forget args
            )
          );
        }
      )
    ) cfg.jobs;

    systemd.services = lib.mapAttrs' (jobName: jobCfg:
      lib.nameValuePair "restic-backups-${jobName}" (
        lib.mkIf jobCfg.enable {
          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "15m"; # Restart after 15 minutes on failure
          };
        }
      )
    ) cfg.jobs;

    environment.systemPackages = with pkgs; [ 
      rclone
      restic-browser
      restic
    ];

    environment.persistence."/persistent".users.yeshey = {
      directories = [
        ".config/rclone/"
        ".config/org.restic.browser/"
      ];
    };

  };
}