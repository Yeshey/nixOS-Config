{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.onedriver;
  onedriverPackage = pkgs.myonedriver;  # allows root and other users to also write in the mounted onedriver
in
{
  options.myHome.onedriver = with lib; {
    enable = mkEnableOption "onedriver";
    onedriverFolder = mkOption {
      type = types.str;
      example = "/mnt/hdd-btrfs/Yeshey/OneDriver";
    };
    serviceCoreName = mkOption {
      type = types.str;
      example = "home-yeshey-OneDriver";
      description = "use `systemd-escape --template onedriver@.service --path /path/to/mountpoint` to figure out";
    };
    periodicallyWipeCache = mkOption {
      type = types.bool;
      default = true;
      description = "Periodically (monthly) wipe the OneDrive cache. Requires a new login when cache is wiped.";
    };
    cliOnlyMode = mkOption {
      type = types.bool;
      default = false;
      description = "Run onedriver in CLI-only mode (with -n flag). Useful to prevent GUI authentication prompts on login if you prefer to authenticate manually via terminal. A helper script will be placed in the mount folder if authentication is needed.";
    };
  };

  config = let
    serviceName = cfg.serviceCoreName; # This is the Nix variable
    onedriverExec = "${onedriverPackage}/bin/onedriver"
      + (if cfg.cliOnlyMode then " -n" else "")
      + " '${cfg.onedriverFolder}'";
    authOnlyOnedriverExec = "${onedriverPackage}/bin/onedriver"
      + (if cfg.cliOnlyMode then " -n" else "")
      + " --auth-only"
      + " '${cfg.onedriverFolder}'";

    runForLoginScriptContent = pkgs.writeShellScriptBin "run-for-onedriver-login-internal" ''
      #!${pkgs.stdenv.shell}
      set -e # Exit immediately if a command exits with a non-zero status.

      MOUNT_POINT="${cfg.onedriverFolder}"
      # Define a shell variable that gets its value from the Nix variable 'serviceName'
      # Use $SHELL_VAR_NAME syntax later in the script for shell expansion
      SHELL_SERVICE_CORE_NAME="${serviceName}"
      ORIGINAL_SCRIPT_NAME="run_for_login.sh" # The name of this script
      ORIGINAL_SCRIPT_PATH="$MOUNT_POINT/$ORIGINAL_SCRIPT_NAME"

      TEMP_SCRIPT_DIR=$(${pkgs.coreutils}/bin/mktemp -d -p "/tmp" onedriver-login-XXXXXX)
      if [ -z "$TEMP_SCRIPT_DIR" ] || [ ! -d "$TEMP_SCRIPT_DIR" ]; then
        echo "FATAL: Could not create temporary directory in /tmp. Exiting."
        exit 1
      fi
      TEMP_SCRIPT_PATH="$TEMP_SCRIPT_DIR/$ORIGINAL_SCRIPT_NAME"

      OPERATION_SUCCESSFUL="false" # Flag to track if onedriver authentication succeeded

      # Cleanup function: always called on exit, SIGINT, SIGTERM
      cleanup() {
        EXIT_STATUS=$? # Capture the exit status of the last command before trap
        echo "----------------------------------------------------------------------"
        echo "Running cleanup procedure for authentication script..."

        if [ "$OPERATION_SUCCESSFUL" = "true" ]; then
          echo "onedriver authentication was successful. Service restart was attempted."
          echo "The temporary script at $TEMP_SCRIPT_PATH and its directory $TEMP_SCRIPT_DIR will be removed."
        else
          echo "onedriver authentication failed or was interrupted (exit status for script: $EXIT_STATUS)."
          # Check if the script was actually moved to the temp location
          if [ -f "$TEMP_SCRIPT_PATH" ]; then
            echo "Attempting to move script from $TEMP_SCRIPT_PATH back to $ORIGINAL_SCRIPT_PATH..."
            # Ensure mount point directory exists (it should, but just in case)
            ${pkgs.coreutils}/bin/mkdir -p "$MOUNT_POINT"
            if ${pkgs.coreutils}/bin/mv -f "$TEMP_SCRIPT_PATH" "$ORIGINAL_SCRIPT_PATH"; then
              echo "Script moved back to $ORIGINAL_SCRIPT_PATH."
              ${pkgs.coreutils}/bin/chmod +x "$ORIGINAL_SCRIPT_PATH" # Ensure it's executable
            else
              echo "ERROR: Failed to move script back to $ORIGINAL_SCRIPT_PATH."
              echo "You may need to manually copy $TEMP_SCRIPT_PATH to $ORIGINAL_SCRIPT_PATH and make it executable."
            fi
          else
            echo "Script was not found at temporary location $TEMP_SCRIPT_PATH. Cannot move back."
            echo "This might happen if the script failed before it could move itself,"
            echo "or if it was already cleaned up from a previous partial run."
            echo "The original script might still be at $ORIGINAL_SCRIPT_PATH if it was never moved."
          fi
        fi

        # Always try to remove the temporary directory
        if [ -d "$TEMP_SCRIPT_DIR" ]; then
          echo "Removing temporary directory: $TEMP_SCRIPT_DIR"
          if ${pkgs.coreutils}/bin/rm -rf "$TEMP_SCRIPT_DIR"; then
            echo "Temporary directory removed."
          else
            echo "ERROR: Failed to remove temporary directory $TEMP_SCRIPT_DIR."
          fi
        fi
        
        if [ "$INTERACTIVE_SHELL" = "true" ] ; then
            echo "Authentication process finished."
            read -p "Press Enter to close this terminal window..."
        fi

        if [ "$OPERATION_SUCCESSFUL" = "true" ]; then
            exit 0
        else
            # Exit with the captured status, or 1 if status was 0 but not successful (e.g. Ctrl+C)
            if [ "$EXIT_STATUS" -eq 0 ]; then
                exit 1 # General error if no specific error code but not successful
            else
                exit "$EXIT_STATUS"
            fi
        fi
      }

      # Set trap for INT (Ctrl+C), TERM (kill), and EXIT (normal exit or error exit due to set -e)
      trap cleanup INT TERM EXIT

      # Check if running in an interactive terminal for the final prompt
      INTERACTIVE_SHELL="false"
      if [ -t 0 ] ; then
          INTERACTIVE_SHELL="true"
      fi

      echo "onedriver Authentication Helper Script"
      echo "----------------------------------------------------------------------"
      echo "This script will:"
      echo "1. Attempt to authenticate onedriver."
      echo "2. If successful, restart the systemd service: onedriver@$SHELL_SERVICE_CORE_NAME.service"
      echo "----------------------------------------------------------------------"
      echo "Original script location: $ORIGINAL_SCRIPT_PATH"
      echo "Temporary script location: $TEMP_SCRIPT_PATH"
      echo "Mount point: $MOUNT_POINT"
      echo "----------------------------------------------------------------------"

      # Before doing anything, check if this script is already running from the temp path
      CURRENT_EXECUTING_SCRIPT_PATH="$(${pkgs.coreutils}/bin/readlink -f "$0")"

      if [ "$CURRENT_EXECUTING_SCRIPT_PATH" = "$TEMP_SCRIPT_PATH" ]; then
        echo "Warning: Script appears to be already running from the temporary location."
        echo "This might indicate a previous run was interrupted."
        echo "Proceeding with onedriver authentication..."
      elif [ -f "$ORIGINAL_SCRIPT_PATH" ]; then
        echo "Moving script from $ORIGINAL_SCRIPT_PATH to $TEMP_SCRIPT_PATH to prepare for onedriver authentication."
        # onedriver --auth-only might still require the mount point to be clear or unmounted.
        if ! ${pkgs.coreutils}/bin/mv -f "$ORIGINAL_SCRIPT_PATH" "$TEMP_SCRIPT_PATH"; then
            echo "FATAL: Failed to move script to temporary location $TEMP_SCRIPT_PATH. Exiting."
            exit 1
        fi
        echo "Script moved successfully."
      else
        echo "Warning: Original script not found at $ORIGINAL_SCRIPT_PATH."
        echo "This script ($CURRENT_EXECUTING_SCRIPT_PATH) might have been moved manually or by a previous incomplete run."
        echo "Assuming this script is the one to manage and proceeding with authentication."
      fi

      echo "----------------------------------------------------------------------"
      echo "Attempting to authenticate onedriver (auth-only mode)..."
      # Nix will interpolate the value of authOnlyOnedriverExec here
      echo "Command: ${authOnlyOnedriverExec}"
      echo "----------------------------------------------------------------------"

      set +e # Temporarily disable exit on error for the onedriver command
      ${authOnlyOnedriverExec} # Execute the onedriver --auth-only command
      ONEDRIVER_AUTH_EXIT_CODE=$?
      set -e # Re-enable exit on error

      echo "----------------------------------------------------------------------"
      if [ $ONEDRIVER_AUTH_EXIT_CODE -eq 0 ]; then
        echo "onedriver authentication command finished successfully (exit code 0)."
        OPERATION_SUCCESSFUL="true" # Signal success to the cleanup trap
        
        echo "Attempting to restart systemd service: onedriver@$SHELL_SERVICE_CORE_NAME.service"
        # Check current service state for better logging
        if ${pkgs.systemd}/bin/systemctl --user is-active --quiet "onedriver@$SHELL_SERVICE_CORE_NAME.service"; then
            echo "Service is currently active, attempting restart..."
        elif ${pkgs.systemd}/bin/systemctl --user is-failed --quiet "onedriver@$SHELL_SERVICE_CORE_NAME.service"; then
            echo "Service is in a failed state, attempting reset and restart..."
            # Try to reset failed state before restarting
            ${pkgs.systemd}/bin/systemctl --user reset-failed "onedriver@$SHELL_SERVICE_CORE_NAME.service"
        else
            echo "Service is currently inactive or in an unknown state, attempting start/restart..."
        fi
        
        set +e # systemctl restart can fail
        ${pkgs.systemd}/bin/systemctl --user restart "onedriver@$SHELL_SERVICE_CORE_NAME.service"
        SYSTEMCTL_EXIT_CODE=$?
        set -e

        if [ $SYSTEMCTL_EXIT_CODE -eq 0 ]; then
          echo "systemctl restart command issued successfully for onedriver@$SHELL_SERVICE_CORE_NAME.service."
          echo "You can check the service status with: systemctl --user status onedriver@$SHELL_SERVICE_CORE_NAME.service"
        else
          echo "ERROR: systemctl restart command failed with exit code $SYSTEMCTL_EXIT_CODE for onedriver@$SHELL_SERVICE_CORE_NAME.service."
          echo "The service may not have started. Please check its status manually."
          # OPERATION_SUCCESSFUL remains true because authentication itself was successful.
          # The service restart failure is a subsequent, distinct issue.
        fi
      else # ONEDRIVER_AUTH_EXIT_CODE -ne 0
        echo "onedriver authentication command failed with exit code $ONEDRIVER_AUTH_EXIT_CODE."
        echo "The script will be restored to $ORIGINAL_SCRIPT_PATH."
        # OPERATION_SUCCESSFUL remains false
        echo "Please check the output above for errors from onedriver."
      fi

      # The trap on EXIT will handle the rest:
      # - Moving script back if OPERATION_SUCCESSFUL is false
      # - Removing temp directory
      # - Final prompt
      # - Exiting with appropriate status
    '';
  in lib.mkIf (config.myHome.enable && cfg.enable) {

    home.packages = [
      onedriverPackage
    ];

    # Helper service to create the run_for_login.sh script on main service failure
    systemd.user.services."onedriver-create-login-helper@${serviceName}" = let
      doTheThing = pkgs.writeShellScriptBin "create-onedriver-login-script" ''
          #!${pkgs.stdenv.shell}
          set -e
          MOUNT_POINT="${cfg.onedriverFolder}"
          LOGIN_SCRIPT_PATH="$MOUNT_POINT/run_for_login.sh"

          # Only create the login script if the mount directory is empty.
          # This is a heuristic: if it's not empty, onedriver might be partially working,
          # or the user has other files there. We don't want to overwrite.
          # Also check if the login script itself already exists.
          if [ -z "$(${pkgs.coreutils}/bin/ls -A "$MOUNT_POINT" 2>/dev/null)" ] || [ ! -e "$LOGIN_SCRIPT_PATH" ]; then
            echo "onedriver service failed. Creating login script at $LOGIN_SCRIPT_PATH"
            ${pkgs.coreutils}/bin/cp -f "${runForLoginScriptContent}/bin/run-for-onedriver-login-internal" "$LOGIN_SCRIPT_PATH"
            ${pkgs.coreutils}/bin/chmod +x "$LOGIN_SCRIPT_PATH"
            echo "Login script created. You can run it manually: $LOGIN_SCRIPT_PATH"
          else
            echo "onedriver service failed, but $MOUNT_POINT is not empty or $LOGIN_SCRIPT_PATH already exists."
            echo "Not creating/overwriting login script."
          fi
        '';
      in {
      Unit = {
        Description = "Helper to create onedriver login script for ${cfg.onedriverFolder} on failure";
        # This service is not meant to be enabled directly, but triggered
      };
      Service = {
        Type = "oneshot";
        # This script checks if the mount folder is empty before creating the login script
        ExecStart = "${doTheThing}/bin/create-onedriver-login-script";
      };
      Install.WantedBy = [ "default.target" ]; # makes it start on every boot
    };

    # Make sure mountpoint folder exists
    systemd.user.services."mountpoint-folder-onedriver" = let
      script = pkgs.writeShellScriptBin "mountpoint-folder-onedriver-script" ''
          ${pkgs.coreutils}/bin/mkdir -p '${cfg.onedriverFolder}' 
        '';
    in {
      Unit = {
        Description = "mountpoint-folder-onedriver";
      };
      Service = { 
        Type = "oneshot";
        ExecStart = "${script}/bin/mountpoint-folder-onedriver-script";
      };
      Install.WantedBy = [ "default.target" ]; # makes it start on every boot
    };

    # Automount Onedriver
    systemd.user.services."onedriver@${serviceName}" = let
      wrapperDir = "/run/wrappers"; 
      # I hate it so much that I-m waiting for network like this bc there in no fucking way to make it work with After in a systemd user service
      waitForNetwork = pkgs.writeShellScriptBin "wait_for_network" ''
            until ${pkgs.iputils}/bin/ping -c1 google.com ; do ${pkgs.coreutils}/bin/sleep 5 ; done
          '';
    in {

        Unit = {
          Description = "onedriver";
          After = [ "network.target" "network-online.target" ];

        };

        Service = {
          ExecStartPre = "${waitForNetwork}/bin/wait_for_network";
          ExecStart = onedriverExec;
          ExecStopPost = "${wrapperDir}/bin/fusermount -uz '${cfg.onedriverFolder}'";
          Restart = "on-abnormal";
          RestartSec = "3";
          RestartForceExitStatus = "2";
        };

        Install = {
          WantedBy = [ "default.target" ]; 
        };
      };

    # A systemd timer and service to delete all the cached files so it doesnt start taking up space
    systemd.user.services."delete-onedriver-cache" = lib.mkIf cfg.periodicallyWipeCache (let
      script = pkgs.writeShellScriptBin "delete-onedriver-cache-script" ''
            ${onedriverPackage}/bin/onedriver --wipe-cache
          '';
    in {
      Unit = {
        Description = "delete-onedriver-cache";
      };
      Service = { 
        Type = "oneshot";
        ExecStart = "${script}/bin/delete-onedriver-cache-script"; # "${mystuff}/bin/doyojob";
      };
    });
    systemd.user.timers."delete-onedriver-cache" = {
      Unit.Description = "delete-onedriver-cache schedule";
      Timer = {
        Unit = "delete-onedriver-cache.service";
        OnCalendar = "monthly";
        Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
      };
      Install.WantedBy = [ "timers.target" ]; # the timer starts with timers
    };
    
  };
}