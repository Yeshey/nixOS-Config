# restore with:
# sudo -E \
#   RESTIC_REPOSITORY="rclone:OneDriveISCTE:Backups/ResticBackups/servers" \
#   RESTIC_PASSWORD="123456789" \
#   RCLONE_CONFIG="/home/yeshey/.config/rclone/rclone.conf" \
#   restic restore latest \
#     --target / \
#     --include "/home/yeshey" \
#     --verbose
{ ... }: # TODO impermanence
# Remember to persist:
#   NixOS:       /var/lib/restic-flags
#   Home-Manager: $XDG_STATE_HOME/restic-flags  (typically ~/.local/state/restic-flags)
let
  # ===========================================================================
  # HELPER FUNCTIONS
  # ===========================================================================

  # notify-send-all: sends a desktop notification to every logged-in GUI user.
  # Intended to be called from root-owned systemd services.
  # We iterate /run/user/* (each entry is a numeric UID), skip root (0),
  # resolve the username with `id -nu`, then sudo to that user with their
  # D-Bus session bus address so notify-send reaches their compositor.
  mkNotifySendAll = pkgs: pkgs.writeShellScriptBin "notify-send-all" ''
    display_help() {
      echo "Send a notification to all logged-in GUI users."
      echo ""
      echo "Usage: notify-send-all [options] <summary> [body]"
      echo ""
      echo "All notify-send options are supported, see below..."
      echo ""
      ${pkgs.libnotify}/bin/notify-send --help
      exit 0
    }

    while [ $# -gt 0 ]; do
      case $1 in
        -h | --help) display_help ;;
        *) break ;;
      esac
    done

    for dir in /run/user/*; do
      uid=$(basename "$dir")
      # Skip root's XDG_RUNTIME_DIR (uid 0)
      [ "$uid" = "0" ] && continue
      # Resolve numeric UID to a username; skip if user no longer exists
      username=$(${pkgs.coreutils}/bin/id -nu "$uid" 2>/dev/null) || continue
      /run/wrappers/bin/sudo \
        -u "$username" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
        ${pkgs.libnotify}/bin/notify-send "$@" || true
    done
  '';

  # ---------------------------------------------------------------------------
  # Shared option definitions (both NixOS and home-manager modules)
  # ---------------------------------------------------------------------------
  jobOptions = lib: {
    enable             = lib.mkEnableOption "this backup job";
    paths              = lib.mkOption { type = lib.types.listOf lib.types.str; };
    rcloneRemoteName   = lib.mkOption { type = lib.types.str; };
    rcloneRemotePath   = lib.mkOption { type = lib.types.str; };
    passwordFile       = lib.mkOption { type = lib.types.path; };
    initialize         = lib.mkOption { type = lib.types.bool;  default = false; };
    startAt            = lib.mkOption { type = lib.types.str;   default = "*-*-* 14:00:00"; };
    randomizedDelaySec = lib.mkOption { type = lib.types.str;   default = "5h"; };
    extraBackupArgs    = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
    exclude            = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
    prune.enable       = lib.mkOption { type = lib.types.bool;  default = true; };
    prune.keep = {
      within  = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
      daily   = lib.mkOption { type = lib.types.nullOr lib.types.int; default = 7; };
      weekly  = lib.mkOption { type = lib.types.nullOr lib.types.int; default = 4; };
      monthly = lib.mkOption { type = lib.types.nullOr lib.types.int; default = 12; };
      yearly  = lib.mkOption { type = lib.types.nullOr lib.types.int; default = null; };
    };
  };

  jobOptionsNixos = lib: {
    user             = lib.mkOption { type = lib.types.str; };
    rcloneConfigFile = lib.mkOption { type = lib.types.path; };
  };

  # mkBackup: produces the attrset passed to services.restic.backups.<name>
  mkBackup = pkgs: lib: flagFile: notifyStartCmd: notifySuccessCmd: notifyFailCmd: job: {
    paths        = job.paths;
    repository   = "rclone:${job.rcloneRemoteName}:${job.rcloneRemotePath}";
    passwordFile = job.passwordFile;
    initialize   = job.initialize;

    exclude = [
      # Build artifacts & package managers
      ".cache"        "Cache"          ".cargo"        "target"
      ".git"          "node_modules"   "_build"
      "venv"          ".venv"          ".npm"          ".gradle"
      ".rustup"       ".expo"          ".vagrant.d"

      # Browsers
      ".floorp"       ".mozilla"       ".tor project"
      ".config/BraveSoftware"   ".config/vivaldi"
      ".config/microsoft-edge"

      # Editors & IDEs
      ".config/VSCodium"   ".config/Code"
      ".vscode-oss"        ".vscode"        ".zed_server"

      # Games & launchers
      "Steam"         "Games"
      ".local/share/bottles"
      ".local/share/umu"
      ".local/share/vital"
      ".local/share/godot"

      # App configs not worth backing up
      ".config/heroic"           ".config/vesktop"
      ".config/syncthing"        ".config/Exodus"
      ".config/libreoffice"      ".config/GitHub Desktop"
      ".config/.android"

      # .local/share large/reconstructible data
      ".var"
      ".local/share/flatpak"
      ".local/share/baloo"
      ".local/share/waydroid"
      ".local/share/zed"
      ".local/share/Smart Code ltd"
      ".local/share/io.appflowy.appflowy"
      ".local/share/yoshimi"
      ".local/share/teamviewer15"
      ".local/share/gnome-shell"
      ".local/share/epiphany"
      ".local/share/okular"
      ".local/share/kactivitymanagerd"
      ".local/share/geary"
      ".local/share/qBittorrent"
      ".local/share/nvim"
      ".local/share/copyous@boerdereinar.dev"
      ".local/share/overboard"  

      # Home large dirs
      "Trash"         "OneDrive"         # OneDrive: would be a recursive backup!
      "AppFiles"      "Downloads"
      "winboat"       ".winboat"         "VirtualBox VMs"
      ".stremio-server"                  ".wine"
      ".texlive*"     ".nv"              ".compose-cache"
      ".anydesk"      ".helm"            ".wine-overboard"

      # Flagged: uncomment to keep these instead
      ".thunderbird"                     # email - keep if you use local folders
      "Zotero"        ".zotero"          # research refs - keep if important
    ] ++ job.exclude;

    extraBackupArgs = [ "--verbose=2" "--exclude-caches" ] ++ job.extraBackupArgs;

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
      mkdir -p "$(dirname "${flagFile}")"
      touch "${flagFile}"
      ${notifyStartCmd}
    '';

    backupCleanupCommand = ''
      if [ "''${SERVICE_RESULT:-}" = "success" ]; then
        echo "Backup finished successfully - removing recovery flag."
        rm -f "${flagFile}"
        ${notifySuccessCmd}
      else
        echo "Backup failed or was interrupted (SERVICE_RESULT=''${SERVICE_RESULT:-unknown}) - keeping recovery flag for reboot-resume."
        ${notifyFailCmd}
      fi
    '';
  };

in
{
  # ==========================================================================
  # NIXOS SYSTEM MODULE
  # ==========================================================================
  flake.modules.nixos.restic-rclone-backups =
    { config, lib, pkgs, ... }:
    let
      notify-send-all = mkNotifySendAll pkgs;
    in
    {
      options.restic-rclone-backups.jobs = lib.mkOption {
        default = {};
        type    = lib.types.attrsOf (lib.types.submodule {
          options = (jobOptions lib) // (jobOptionsNixos lib);
        });
      };

      config = lib.mkIf (config.restic-rclone-backups.jobs != {}) {

        services.restic.backups = lib.mapAttrs (jobName: job:
          let
            flagFile         = "/var/lib/restic-flags/${jobName}.flag";
            notifyStartCmd   = ''${notify-send-all}/bin/notify-send-all "System Backup" "Starting: ${jobName}…" --icon=drive-harddisk --urgency=low || true'';
            notifySuccessCmd = ''${notify-send-all}/bin/notify-send-all "System Backup" "Finished: ${jobName}" --icon=drive-harddisk || true'';
            notifyFailCmd    = ''${notify-send-all}/bin/notify-send-all "System Backup" "FAILED: ${jobName}" --icon=dialog-error --urgency=critical || true'';
          in
          lib.mkIf job.enable (
            (mkBackup pkgs lib flagFile notifyStartCmd notifySuccessCmd notifyFailCmd job) // {
              user             = job.user;
              rcloneConfigFile = job.rcloneConfigFile;
            }
          )
        ) config.restic-rclone-backups.jobs;

        systemd.services = lib.mkMerge [
          (lib.mapAttrs' (jobName: job:
            lib.nameValuePair "restic-backups-${jobName}" (lib.mkIf job.enable {
              environment.RESTIC_PROGRESS_FPS = "0.016666"; # every min progress report
              serviceConfig = {
                Restart    = "on-failure";
                RestartSec = "5m";
              };
            })
          ) config.restic-rclone-backups.jobs)

          {
            restic-resume-check = {
              description = "Resume interrupted system restic backups after reboot";
              wantedBy    = [ "multi-user.target" ];
              after       = [ "local-fs.target" ];
              script      = ''
                if [ -d /var/lib/restic-flags ]; then
                  for flag in /var/lib/restic-flags/*.flag; do
                    [ -e "$flag" ] || continue
                    # Pure bash alternative to basename
                    filename="''${flag##*/}"
                    jobName="''${filename%.flag}"
                    echo "Found interrupted backup for '$jobName', restarting..."
                    systemctl start "restic-backups-$jobName.service" --no-block || true
                  done
                fi
              '';
              serviceConfig.Type = "oneshot";
            };
          }
        ];

        environment.systemPackages = with pkgs; [ rclone restic libnotify notify-send-all ];
      };
    };

# ==========================================================================
  # HOME MANAGER MODULE
  # ==========================================================================
  flake.modules.homeManager.restic-rclone-backups =
    { config, lib, pkgs, ... }:
    {
      options.restic-rclone-backups.jobs = lib.mkOption {
        default = {};
        type    = lib.types.attrsOf (lib.types.submodule {
          options = jobOptions lib;
        });
      };

      config =
        let
          enabledJobs = lib.filterAttrs (_: job: job.enable) config.restic-rclone-backups.jobs;

          resumeScript = pkgs.writeShellScript "restic-user-resume" ''
            flagDir="${config.xdg.stateHome}/restic-flags"
            if [ -d "$flagDir" ]; then
              for flag in "$flagDir"/*.flag; do
                [ -e "$flag" ] || continue
                # Pure bash alternative to basename
                filename="''${flag##*/}"
                jobName="''${filename%.flag}"
                echo "Found interrupted backup for '$jobName', restarting..."
                systemctl --user start "restic-backups-$jobName.service" --no-block || true
              done
            fi
          '';
        in
        lib.mkIf (enabledJobs != {}) {
          services.restic.enable  = true;
          services.restic.backups = lib.mapAttrs (jobName: job:
            let
              flagFile = "${config.xdg.stateHome}/restic-flags/${jobName}.flag";
              
              # Simple logic: wait for action, if it's "logs", open the terminal.
              notifyCmd = summary: body: icon: ''
                (
                  # D-Bus / notification daemon may not be ready yet (e.g. backup starts
                  # immediately on login before the compositor is fully up). Retry a few
                  # times before giving up.
                  notify_with_retry() {
                    local attempts=0
                    until ${pkgs.libnotify}/bin/notify-send \
                            --action="logs=View Logs" \
                            --icon=${icon} \
                            --urgency=critical \
                            --wait \
                            "${summary}" "${body}" 2>/dev/null; do
                      attempts=$((attempts + 1))
                      [ $attempts -ge 10 ] && return 1
                      sleep 10
                    done
                  }

                  ret_val=$(notify_with_retry)
                  case "$ret_val" in
                    "logs")
                      ${pkgs.systemd}/bin/systemd-run --user --no-block \
                        ${pkgs.xdg-terminal-exec}/bin/xdg-terminal-exec \
                        ${pkgs.systemd}/bin/journalctl --user -fu restic-backups-${jobName}.service
                      ;;
                  esac
                ) &
              '';

            in
            mkBackup pkgs lib flagFile 
              (notifyCmd "User Backup" "Starting: ${jobName}…" "drive-harddisk") # notifyStartCmd
              ''${pkgs.libnotify}/bin/notify-send "User Backup" "Finished: ${jobName}" --icon=drive-harddisk'' # notifySuccessCmd
              (notifyCmd "User Backup" "FAILED/STOPPED: ${jobName}" "dialog-error") # notifyFailCmd
              job
          ) enabledJobs;

          systemd.user.services = lib.mkMerge [
            # Restart-on-failure for each backup job
            (lib.mapAttrs' (jobName: _:
              lib.nameValuePair "restic-backups-${jobName}" {
                Service = {
                  Environment = "RESTIC_PROGRESS_FPS=0.016666"; # every min progress report
                  Restart    = "on-failure";
                  RestartSec = "5m";
                };
              }
            ) enabledJobs)

            # Resume-after-login service
            {
              restic-resume-check = {
                Unit = {
                  Description = "Resume interrupted user restic backups after login";
                  After       = [ "default.target" ];
                };
                Install.WantedBy = [ "default.target" ];
                Service = {
                  Type      = "oneshot";
                  ExecStart = "${resumeScript}";
                };
              };
            }
          ];

          home.packages = with pkgs; [ rclone restic libnotify ];
        };
    };
}