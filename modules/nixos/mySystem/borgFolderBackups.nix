{
  config,
  lib,
  pkgs,
  ...
}:
# backs up a folder tomewhere and changes all premissions to be of a user.

let
  cfg = config.mySystem.borgFolderBackups;
in
{
  options.mySystem.borgFolderBackups = with lib; {
    jobs = mkOption {
      type = types.attrsOf (types.submodule ({ name, config, ... }: {
        options = {
          user = mkOption {
            type = types.str;
            default = "yeshey"; # config.mySystem.user;
            description = "User to own the backup repository";
          };
          repo = mkOption {
            type = types.str;
            description = "Path to the backup repository";
          };
          paths = mkOption {
            type = types.listOf types.str;
            description = "List of paths to back up";
          };
          exclude = mkOption {
            type = types.listOf types.str;
            default = [
              ".cache"
              "*/cache2"
              "*/Cache"
              ".config/Slack/logs"
              ".config/Code/CachedData"
              ".container-diff"
              ".npm/_cacache"
              "*/node_modules"
              "*/bower_components"
              "*/_build"
              "*/.tox"
              "*/venv"
              "*/.venv"
              "*cache*"
              "*/Android"
              "*/.gradle"
              "*/.var"
              "*/.cabal"
              "*/.vscode"
              "*/.stremio-server"
              "*/grapejuice"
              "*/baloo"
              "*/share/containers"
              "*/lutris"
              "*/Steam"
              "*/.config"
              "*/Trash"
              "*/Games"
            ];
            description = "List of patterns to exclude from the backup";
          };
          encryption = {
            mode = mkOption {
              type = types.str;
              default = "none";
              description = "Encryption mode for the backup repository";
            };
          };
          extraCreateArgs = mkOption {
            type = types.str;
            default = "--stats";
            description = "Extra arguments passed to borg create";
          };
          compression = mkOption {
            type = types.str;
            default = "auto,lzma";
            description = "Compression algorithm to use";
          };
          prune = {
            keep = {
              within = mkOption {
                type = types.str;
                default = "1d";
                description = "Keep all archives within this timeframe";
              };
              weekly = mkOption {
                type = types.int;
                default = 2;
                description = "Number of weekly archives to keep";
              };
              yearly = mkOption {
                type = types.int;
                default = 3;
                description = "Number of yearly archives to keep";
              };
            };
          };
          startAt = mkOption {
            type = types.str;
            default = "weekly";
            description = "When to trigger the backup";
          };
          persistentTimer = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to use a persistent timer";
          };
          onedriver = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to check for and wait for a onedriver mount in preHook.";
            };
            mountPath = mkOption {
              type = types.str;
              default = "/home/yeshey/OneDriverISCTE"; # Your default
              description = "The path where onedriver is expected to be mounted.";
            };
          };
        };
      }));
      default = {};
      description = "Borg backup jobs for folders";
    };
  };

  config = lib.mkIf (cfg.jobs != {}) {
    services.borgbackup.jobs = lib.mapAttrs (name: job: 
      let
        # Script to:
        # 1. (Optionally) Wait for onedriver mount
        # 2. Create the borg repo directory with correct permissions
        # This script is unique per job due to job-specific variables.
        waitForOnedriverScript = pkgs.writeShellScriptBin "wait-for-onedriver-${name}" 
          ''
            #!${pkgs.stdenv.shell}
            set -eu # Exit on error, treat unset variables as error

            JOB_REPO_PATH="${job.repo}"
            JOB_USER="${job.user}"

            ONEDRIVER_ENABLED="true"
            ONEDRIVER_MOUNT_PATH="${job.onedriver.mountPath}"

            # Part 1: Wait for Onedriver
            echo "Job '${name}': Onedriver check enabled. Verifying mount at ''${ONEDRIVER_MOUNT_PATH}..."

            MAX_CHECKS=10 # Wait for up to 10 minutes (10 checks * 60 seconds)
            CHECKS_DONE=0
            
            while ! ${pkgs.busybox}/bin/mount | grep -q " ''${ONEDRIVER_MOUNT_PATH} "; do # Note the spaces for exact match
              CHECKS_DONE=$((CHECKS_DONE + 1))
              if [ "''${CHECKS_DONE}" -gt "''${MAX_CHECKS}" ]; then
                echo "Job '${name}': Onedriver not mounted at ''${ONEDRIVER_MOUNT_PATH} after 10 minutes. Exiting with error." >&2
                exit 1 # Critical error, backup should fail
              fi
              echo "Job '${name}': Onedriver not mounted yet (check ''${CHECKS_DONE}/''${MAX_CHECKS}). Waiting 60 seconds..."
              sleep 60
            done
            echo "Job '${name}': Onedriver is mounted at ''${ONEDRIVER_MOUNT_PATH}."
          '';
      in {
        inherit (job) paths exclude startAt persistentTimer;
        # user = job.user;
        repo = job.repo;
        encryption.mode = job.encryption.mode;
        extraCreateArgs = job.extraCreateArgs;
        compression = job.compression;
        prune.keep = job.prune.keep;
        preHook = lib.mkIf job.onedriver.enable "${waitForOnedriverScript}/bin/wait-for-onedriver-${name}";
        postHook = "chown -R ${job.user} ${job.repo}";
    }) cfg.jobs;

    systemd.tmpfiles.rules = lib.concatLists (lib.mapAttrsToList (name: job: 
      # Only create tmpfiles rules for jobs where onedriver is not enabled
      if !(job.onedriver.enable or false) then [
        "d ${job.repo} 0700 ${job.user} ${job.user} -"
      ] else []
    ) cfg.jobs);
  };
}