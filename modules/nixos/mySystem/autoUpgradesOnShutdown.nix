{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.autoUpgradesOnShutdown;
  notify-send-all = pkgs.writeShellScriptBin "notify-send-all" ''
    # ... (notify-send-all script remains unchanged) ...
    # https://github.com/tonywalker1/notify-send-all/tree/main
    # MIT License
    #
    # Copyright (c) 2022  Tony Walker
    #
    # Permission is hereby granted, free of charge, to any person obtaining a copy
    # of this software and associated documentation files (the "Software"), to deal
    # in the Software without restriction, including without limitation the rights
    # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    # copies of the Software, and to permit persons to whom the Software is
    # furnished to do so, subject to the following conditions:
    #
    # The above copyright notice and this permission notice shall be included in all
    # copies or substantial portions of the Software.
    #
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    # SOFTWARE.
    #
    #

    display_help() {
        echo "Send a notification to all logged-in GUI users."
        echo ""
        echo "Usage: notify-send-all [options] <summary> [body]"
        echo ""
        echo "Options:"
        echo "  -? | --help    This text."
        echo ""
        echo "All options from notify-send are supported, see below..."
        echo
        ${pkgs.libnotify}/bin/notify-send --help
        exit 1
    }

    while [ $# -gt 0 ]; do
        case $1 in
            -h | --help)
                display_help
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done

    for SOME_USER in /run/user/*; do
        SOME_USER_ID=$(basename "$SOME_USER")
        # Check if SOME_USER_ID is a valid number (UID)
        if [[ "$SOME_USER_ID" =~ ^[0-9]+$ ]] && [ "$SOME_USER_ID" != 0 ]; then
             # Get username from UID
             SOME_USER_NAME=$(id -u -n "$SOME_USER_ID" 2>/dev/null)
             # Proceed only if username resolution is successful
             if [ -n "$SOME_USER_NAME" ]; then
                 /run/wrappers/bin/sudo -u "$SOME_USER_NAME" \
                     DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/"$SOME_USER_ID"/bus ${pkgs.libnotify}/bin/notify-send "$@" || echo "Failed to notify user $SOME_USER_NAME (UID $SOME_USER_ID)" >&2
             #else
                 #echo "* Skipping UID $SOME_USER_ID (no username found or other error)." >&2
             fi
        #else
            #echo "* Skipping non-UID entry $SOME_USER_ID." >&2
        fi
    done

    exit 0
  '';
in
{
  options.mySystem.autoUpgradesOnShutdown = {
    enable = lib.mkEnableOption "autoUpgradesOnShutdown";
    gitRepo = lib.mkOption {
      default = "git@github.com:Yeshey/nixOS-Config.git";
      type = lib.types.str;
      example = "git@github.com:Yeshey/nixOS-Config.git";
      description = ''
        the ssh clone link of your configuration flake repo
      '';
    };
    ssh_key = lib.mkOption {
      default = "/home/yeshey/.ssh/my_identity";
      type = lib.types.str;
      example = "/home/yeshey/.ssh/my_identity";
      description = ''
        The path to the ssh identity key to access the git repository
      '';
    };
    host = lib.mkOption {
      type = lib.types.str;
      example = "kakariko";
      description = ''
        name of config to build
      '';
    };
    dates = lib.mkOption {
      type = lib.types.str;
      example = "weekly";
      default = "*-*-1/3"; # every 3 days
      description = ''
        how frequently to update
      '';
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) { # Fixed: Check config.mySystem.autoUpgradesOnShutdown.enable

    environment.systemPackages = with pkgs; [
      libnotify # Dependency for notify-send
      notify-send-all
    ];

    systemd.timers.my-nixos-upgrade = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true;
        OnCalendar = cfg.dates;
        Unit = "my-nixos-upgrade.service";
      };
    };

    systemd.services.my-nixos-upgrade =
    let
      nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
      date     = "${pkgs.coreutils}/bin/date";
      readlink = "${pkgs.coreutils}/bin/readlink";
      shutdown = "${config.systemd.package}/bin/shutdown";
      operation = "boot";
      gitScript = pkgs.writeShellScriptBin "update-git-repo" ''
        #!${pkgs.bash}/bin/bash
        set -e # Exit on error to simplify logic

        export SSH_KEY="${cfg.ssh_key}"
        export GIT_SSH_COMMAND="ssh -i ${cfg.ssh_key} -o StrictHostKeyChecking=no"
        UPGRADE_DIR="/tmp/upgradeOnShutdown"

        echo "Cloning the latest version of the repo to $UPGRADE_DIR"
        rm -rf "$UPGRADE_DIR"
        ${pkgs.git}/bin/git clone --depth 1 ${cfg.gitRepo} "$UPGRADE_DIR"

        # Function to attempt an upgrade and return status
        attempt_upgrade() {
          local desc="$1"
          shift # Remove description from args
          echo "Attempting upgrade: $desc"
          ${nixos-rebuild} ${operation} --flake "$UPGRADE_DIR#${cfg.host}" "$@"
        }

        # Function to rollback flake.lock
        rollback_lock() {
          echo "Rolling back flake.lock..."
          ${pkgs.git}/bin/git -C "$UPGRADE_DIR" checkout -- flake.lock
        }

        # --- Try different upgrade strategies ---

        # 1. Try updating (almost) all inputs first via flake update then rebuild
        echo "Trying to update (almost) all specified flake inputs in flake.lock"
        if ${pkgs.nix}/bin/nix flake update --flake "$UPGRADE_DIR" \
          nixpkgs \
          nixpkgs-unstable \
          home-manager \
          neovim-plugins \
          stylix \
          plasma-manager \
          nurpkgs \
          hyprland \
          hyprland-plugins \
          hyprland-contrib \
          nixos-nvidia-vgpu \
          fastapi-dls-nixos \
          learnWithT \
          impermanence \
          deploy-rs \
          agenix \
          nixos-generators \
          nix-on-droid \
          box64-binfmt \
          nix-luanti \
          nix-minecraft \
          nix-snapd && \
           attempt_upgrade "Build with all inputs updated"; then
          echo "Full flake update and rebuild successful."
        # 2. If full update/rebuild failed, try updating only nixpkgs and home-manager during rebuild
        elif ( rollback_lock && attempt_upgrade "Update nixpkgs, home-manager" --update-input nixpkgs --update-input home-manager ); then
          echo "Upgrade with nixpkgs, home-manager successful."
        # 3. If that failed, try updating only nixpkgs during rebuild
        elif ( rollback_lock && attempt_upgrade "Update nixpkgs only" --update-input nixpkgs ); then
          echo "Upgrade with nixpkgs only successful."
        # 4. If all updates failed, try rebuilding with the original lock file
        elif ( rollback_lock && attempt_upgrade "Build with original lock file" ); then
           echo "Rebuild with original lock file successful (no updates applied)."
        # 5. If even the original config fails to build, something is very wrong
        else
          rollback_lock # Ensure lock is rolled back
          echo "FATAL: All upgrade attempts failed, including rebuild with original lock file. No changes applied." >&2
          exit 1 # Signal failure
        fi

        # --- Commit and Push if lock file changed ---
        # Use git diff --quiet to check if flake.lock changed from HEAD
        if ! ${pkgs.git}/bin/git -C "$UPGRADE_DIR" diff --quiet HEAD -- flake.lock; then
          echo "flake.lock changed, committing and pushing..."
          ${pkgs.git}/bin/git -C "$UPGRADE_DIR" add flake.lock
          ${pkgs.git}/bin/git -C "$UPGRADE_DIR" commit -m "Auto Upgrade: Updated flake.lock ($(${date} --iso-8601=seconds))"
          if ${pkgs.git}/bin/git -C "$UPGRADE_DIR" push; then
             echo "Push successful."
          else
             echo "WARNING: Push failed. Lock file updated locally but not pushed." >&2
             # Decide if this should be a fatal error or just a warning
             # exit 1
          fi
        else
          echo "No changes to flake.lock detected, skipping commit/push."
        fi

        echo "Upgrade script finished."
        exit 0
      '';
    in rec {
      description = "NixOS Upgrade on Shutdown";
      # No 'before =' here, relies on systemd's default reverse dependency stop order
      # unless we use `DefaultDependencies=no`

      restartIfChanged = false; # Keep this false for a shutdown service

      # This service should run *before* network/ssh services are stopped during shutdown
      # We also need network *during* its run (ExecStop)
      # Let's explicitly define the shutdown order relative to critical services.
      unitConfig = {
        # Ensures this unit is stopped before the listed units during shutdown.
        # This means ExecStop of my-nixos-upgrade completes *before* sshd/autossh are stopped.
        Before = [ "shutdown.target" "sshd.service" "autossh-reverseProxy.service" ];
        # Conflicts=reboot.target means this service won't run *during* a reboot operation,
        # which is handled by the preStop logic checking the target.
        Conflicts="reboot.target";
        # We probably want DefaultDependencies=no to have full control,
        # but let's try with Before= first as it's less disruptive.
        # DefaultDependencies = "no"; # Consider if Before= alone isn't sufficient
      };

      # Dependencies needed *before* this service *starts* (less relevant for ExecStop logic)
      after = [
        "network-online.target"
        "nss-lookup.target"
        "nix-daemon.service"
        "systemd-user-sessions.service"
        "plymouth-quit-wait.service" # Ensure plymouth splash is gone if applicable
        "sshd.service" # Needed if cloning via ssh as root perhaps? Added for safety.
        "thermald.service" # Example, keep yours
        "systemd-oomd.service" # Keep yours
      ];
      wants = [
        "network-online.target" # Need network during ExecStop
        "nix-daemon.service"    # Need nix-daemon during ExecStop
      ];
      requires = [ # Stricter than wants
         # "network-online.target" # Usually wants is sufficient
         # "nix-daemon.service"
      ];


      environment = config.nix.envVars // {
        inherit (config.environment.sessionVariables) NIX_PATH;
        HOME = "/root"; # Important for git/ssh operations as root
      } // config.networking.proxy.envVars;

      path = with pkgs; [
        coreutils
        gnutar
        xz.bin
        gzip
        gitMinimal
        config.nix.package.out
        config.programs.ssh.package # Needed for ssh client in GIT_SSH_COMMAND
        nix # Need nix CLI for flake update
        bash # For the script shebang and potentially advanced scripting features
      ];

      # ExecStart notifies the user. The service stays active because of RemainAfterExit=yes.
      script = ''
        echo "Auto upgrade service started. Will run upgrade logic on shutdown."
        ${notify-send-all}/bin/notify-send-all -u critical "System Auto-Upgrade Service Activated" "Will attempt to upgrade NixOS configuration on next proper shutdown."
      '';

      # ExecStop performs the upgrade logic, but only on poweroff.
      preStop = ''
          FLAG_FILE="/var/run/nixos-reboot-upgrade.flag" # Use /var/run or /run

          # Check if the target is poweroff.target
          if ! systemctl list-jobs | grep -q 'poweroff.target.*start'; then
            echo "Shutdown target is not poweroff.target (likely reboot or other). Creating flag file $FLAG_FILE to trigger upgrade after next boot."
            # Create flag file to be checked by nixos-reboot-upgrade-check.service
            touch "$FLAG_FILE"
            # Notify user about the delay
            ${notify-send-all}/bin/notify-send-all -u normal "System Upgrade Postponed" "Upgrade will occur after the next boot and subsequent shutdown."
          else
            echo "Poweroff target detected. Proceeding with NixOS upgrade..."
            ${notify-send-all}/bin/notify-send-all -u critical "System Auto-Upgrade Running" "Attempting to upgrade NixOS configuration now. Shutdown may take longer."
            # Execute the upgrade script. Capture output for logging.
            if ${gitScript}/bin/update-git-repo; then
              echo "Upgrade script completed successfully."
              ${notify-send-all}/bin/notify-send-all -u normal "System Auto-Upgrade Success" "NixOS configuration upgraded successfully."
            else
              echo "Upgrade script failed. Check logs for details." >&2
              ${notify-send-all}/bin/notify-send-all -u critical "System Auto-Upgrade Failed" "NixOS configuration upgrade failed. Check system logs."
              # Even on failure, allow shutdown to continue. The system should boot into the last known good generation.
            fi
          fi
        '';

      # postStop cleans up the temporary directory
      postStop = ''
        echo "Cleaning up /tmp/upgradeOnShutdown..."
        rm -rf /tmp/upgradeOnShutdown
        echo "Auto upgrade service stopped."
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes"; # Keep service active until explicitly stopped (during shutdown)
        TimeoutStopSec="10h"; # Generous timeout for the ExecStop (upgrade) process
        # User = "root"; # Service runs as root by default
      };
    };

    # Increase timeout for the poweroff target itself to accommodate long upgrades
    systemd.targets."poweroff" = {
      unitConfig = {
        JobTimeoutSec = "10h"; # Match or exceed the service TimeoutStopSec
      };
    };

    # Service to check for the flag file on boot
    systemd.services.nixos-reboot-upgrade-check = {
      description = "Check for postponed NixOS upgrade flag on boot";
      wantedBy = [ "multi-user.target" ]; # Run after basic system is up
      after = [ "network-online.target" ]; # Ensure network is available if needed later
      requires = [ "network-online.target" ]; # Might need network if upgrade runs immediately
      path = with pkgs; [ coreutils systemd ]; # For rm, echo, systemctl
      script = ''
        FLAG_FILE="/var/run/nixos-reboot-upgrade.flag" # Use /var/run or /run

        if [ -f "$FLAG_FILE" ]; then
          echo "Flag file $FLAG_FILE found. System was likely rebooted instead of powered off during the last scheduled upgrade window."
          echo "The upgrade will be attempted on the *next* proper shutdown."
          echo "Removing flag file $FLAG_FILE."
          # Optionally notify the user
          # ${notify-send-all}/bin/notify-send-all -u normal "Postponed Upgrade Pending" "A system upgrade was postponed and will run on the next shutdown."
          rm -f "$FLAG_FILE" # Remove the flag; the timer will trigger the service again eventually.
        else
          echo "No postponed upgrade flag found."
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}