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
          postHook = mkOption {
            type = types.str;
            default = "";
            description = "Commands to run after the backup";
          };
        };
        config.postHook = lib.mkDefault "chown -R ${config.user} ${config.repo}";
      }));
      default = {};
      description = "Borg backup jobs for folders";
    };
  };

  config = lib.mkIf (cfg.jobs != {}) {
    services.borgbackup.jobs = lib.mapAttrs (name: job: {
      inherit (job) paths exclude startAt persistentTimer;
      repo = job.repo;
      encryption.mode = job.encryption.mode;
      extraCreateArgs = job.extraCreateArgs;
      compression = job.compression;
      prune.keep = job.prune.keep;
      postHook = job.postHook;
    }) cfg.jobs;

    systemd.tmpfiles.rules = lib.concatLists (lib.mapAttrsToList (name: job: [
      "d ${job.repo} 0700 ${job.user} ${job.user} -"
    ]) cfg.jobs);
  };
}