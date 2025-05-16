# copyFoldersOnedriver.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.copyFoldersOnedriver;

  rsyncUserExecScriptContent = jobName: job: pkgs.writeShellScript "rsync-user-exec-${jobName}" ''
    #!${pkgs.stdenv.shell}
    set -eu

    echo "User script for rsync copy job '$RSYNC_JOB_NAME': Starting."
    # ... (other echo lines for env vars) ...

    if [ "$RSYNC_IS_FUSE_REPO" = "true" ]; then
      timeout_str="$RSYNC_FUSE_REPO_CHECK_TIMEOUT"
      interval_str="$RSYNC_FUSE_REPO_CHECK_INTERVAL"
      expected_types_pattern="$RSYNC_FUSE_REPO_EXPECTED_TYPES"

      # Determine the actual path to check for the FUSE mount
      if [ -n "$RSYNC_FUSE_MOUNT_POINT_TO_CHECK" ]; then
        path_to_check_mount_for="$RSYNC_FUSE_MOUNT_POINT_TO_CHECK"
      else
        # Fallback to checking the repo destination path itself, or its parent
        # This might be less reliable if repo is deep and parent is not the direct FUSE mount
        path_to_check_mount_for="$RSYNC_REPO_DEST_DIR"
      fi
      echo "FUSE Repo: Path to check for mount: '$path_to_check_mount_for'"


      timeout_seconds=$(echo "$timeout_str" | ${pkgs.gawk}/bin/awk '{ val=0+substr($0,1,length($0)-1); unit=substr($0,length($0)); if(unit=="m") val*=60; else if(unit=="h") val*=3600; else if(unit!="s" && unit!="") val=0+$0; else val=0+$0; print val; }')
      interval_seconds=$(echo "$interval_str" | ${pkgs.gawk}/bin/awk '{ val=0+substr($0,1,length($0)-1); unit=substr($0,length($0)); if(unit=="m") val*=60; else if(unit=="h") val*=3600; else if(unit!="s" && unit!="") val=0+$0; else val=0+$0; print val; }')
      
      if [ -z "$timeout_seconds" ] || [ "$timeout_seconds" -le 0 ]; then timeout_seconds=180; fi
      if [ -z "$interval_seconds" ] || [ "$interval_seconds" -le 0 ]; then interval_seconds=15; fi

      elapsed_time=0
      fuse_mounted=false

      echo "FUSE Repo: Checking for FUSE mount at '$path_to_check_mount_for' for up to $timeout_seconds seconds..."
      echo "Expecting one of types/sources: $expected_types_pattern"

      while [ "$elapsed_time" -lt "$timeout_seconds" ]; do
        # Use --mountpoint with findmnt if checking a specific mount point path
        # Or --target if checking what filesystem a generic path resides on
        if ${pkgs.util-linux}/bin/findmnt -n --raw --evaluate --output FSTYPE,SOURCE --target "$path_to_check_mount_for" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qE "$expected_types_pattern"; then
          echo "FUSE mount detected for '$path_to_check_mount_for'."
          fuse_mounted=true
          break
        fi
        echo "FUSE mount not yet detected for '$path_to_check_mount_for'. Waiting $interval_seconds seconds..."
        sleep "$interval_seconds"
        elapsed_time=$((elapsed_time + interval_seconds))
      done

      if [ "$fuse_mounted" = "false" ]; then
        echo "CRITICAL: FUSE mount for '$path_to_check_mount_for' (types: $expected_types_pattern) not detected after $timeout_seconds seconds. Aborting job '$RSYNC_JOB_NAME'." >&2
        exit 1
      fi
    else
      echo "Not a FUSE repo or check disabled, proceeding without FUSE mount check."
    fi

    echo "Ensuring destination directory $RSYNC_REPO_DEST_DIR exists..."
    ${pkgs.coreutils}/bin/mkdir -p "$RSYNC_REPO_DEST_DIR"

    echo "Rsyncing from \"$RSYNC_TEMP_SOURCE_DIR/\" to \"$RSYNC_REPO_DEST_DIR/\" ..."
    ${pkgs.coreutils}/bin/sh -c "${pkgs.rsync}/bin/rsync $RSYNC_OPTIONS \"$RSYNC_TEMP_SOURCE_DIR/\" \"$RSYNC_REPO_DEST_DIR/\""

    if [ -n "$RSYNC_POST_HOOK_CMD" ]; then
      echo "Running postHook for job '$RSYNC_JOB_NAME'..."
      ${pkgs.coreutils}/bin/sh -c "$RSYNC_POST_HOOK_CMD"
    fi

    echo "User script for rsync copy job '$RSYNC_JOB_NAME': Finished successfully."
  '';

in
{
  options.mySystem.copyFoldersOnedriver = with lib; {
    jobs = mkOption {
      type = types.attrsOf (types.submodule ({ name, config, ... }: {
        options = {
          user = mkOption { type = types.str; default = "yeshey"; };
          repo = mkOption { type = types.str; description = "Absolute path to the destination directory."; };
          paths = mkOption { type = types.listOf types.str; description = "List of absolute source paths to copy."; };
          startAt = mkOption { type = types.str; default = "weekly"; };
          persistentTimer = mkOption { type = types.bool; default = true; };
          rsyncOptions = mkOption { type = types.str; default = "-a --delete --no-owner --no-group"; };
          postHook = mkOption { type = types.str; default = ""; };
          isFuseRepo = mkOption { type = types.bool; default = true; };
          fuseRepoCheck = {
            timeout = mkOption { type = types.str; default = "3m"; };
            interval = mkOption { type = types.str; default = "15s"; };
            expectedFuseTypes = mkOption {
              type = types.listOf types.str;
              default = [ "onedrive" "fuse.onedrive" "rclone" ];
            };
            # <<< NEW OPTION HERE >>>
            actualMountPointToCheck = mkOption {
              type = types.nullOr types.str; # Nullable string
              default = null;
              description = "Optional. If set, specifies the exact FUSE mount point path to check (e.g., /home/yeshey/OneDrive). If null, the check targets the 'repo' path.";
            };
          };
        };
      }));
      default = {};
    };
  };

  config = lib.mkIf (cfg.jobs != {}) {
    users.users = lib.foldr lib.mergeAttrs {} (
      lib.mapAttrsToList (name: job: { ${job.user}.linger = true; }) cfg.jobs
    );

    systemd.services = lib.mapAttrs' (jobName: job:
      let
        systemServiceName = "rsync-copy-prepare-${jobName}";
        tempCopyParentDir = "/tmp/rsync-staging";
        tempCopyDir = "${tempCopyParentDir}/${jobName}";
        userScriptPath = rsyncUserExecScriptContent jobName job;

        setEnvArgs = lib.concatMapStringsSep " " (kv: "--setenv=${kv.name}=${lib.escapeShellArg kv.value}") ([
          { name = "RSYNC_JOB_NAME"; value = jobName; }
          { name = "RSYNC_TEMP_SOURCE_DIR"; value = tempCopyDir; }
          { name = "RSYNC_REPO_DEST_DIR"; value = job.repo; }
          { name = "RSYNC_OPTIONS"; value = job.rsyncOptions; }
          { name = "RSYNC_POST_HOOK_CMD"; value = job.postHook; }
          { name = "RSYNC_IS_FUSE_REPO"; value = if job.isFuseRepo then "true" else "false"; }
          { name = "RSYNC_FUSE_REPO_CHECK_TIMEOUT"; value = job.fuseRepoCheck.timeout; }
          { name = "RSYNC_FUSE_REPO_CHECK_INTERVAL"; value = job.fuseRepoCheck.interval; }
          { name = "RSYNC_FUSE_REPO_EXPECTED_TYPES"; value = (lib.concatStringsSep "|" job.fuseRepoCheck.expectedFuseTypes); }
        ] ++ (lib.optional (job.fuseRepoCheck.actualMountPointToCheck != null) 
              { name = "RSYNC_FUSE_MOUNT_POINT_TO_CHECK"; value = job.fuseRepoCheck.actualMountPointToCheck; }
        ));

        systemExecScript = pkgs.writeShellScript "rsync-prepare-exec-${jobName}" ''
          #!${pkgs.stdenv.shell}
          set -eu
          # ... (rest of systemExecScript is the same as before, using the new setEnvArgs) ...
          echo "System service for rsync copy job '${jobName}': Starting preparation."
          echo "Ensuring parent temporary directory ${tempCopyParentDir} exists..."
          ${pkgs.coreutils}/bin/mkdir -p "${tempCopyParentDir}"
          ${pkgs.coreutils}/bin/chmod 1777 "${tempCopyParentDir}"

          echo "Cleaning up old job temporary directory ${tempCopyDir}..."
          ${pkgs.coreutils}/bin/rm -rf "${tempCopyDir}"
          ${pkgs.coreutils}/bin/mkdir -p "${tempCopyDir}"

          echo "Copying source paths to ${tempCopyDir}..."
          ${lib.concatMapStringsSep "\n" (path: ''
            echo "Rsyncing ${lib.escapeShellArg path} to ${tempCopyDir}/ ..."
            ${pkgs.rsync}/bin/rsync -aL "${lib.escapeShellArg path}" "${tempCopyDir}/" || {
              echo "ERROR: Failed to rsync ${lib.escapeShellArg path} to ${tempCopyDir}. Aborting." >&2
              exit 1
            }
          '') job.paths}
          echo "All source paths rsynced to ${tempCopyDir}."

          echo "Setting final permissions on ${tempCopyDir} for user ${job.user}..."
          ${pkgs.coreutils}/bin/chown -R ${lib.escapeShellArg job.user} "${tempCopyDir}"
          ${pkgs.coreutils}/bin/chmod u+rwx "${tempCopyDir}"

          echo "Triggering user script directly for user ${job.user}..."
          echo "User script to execute: ${userScriptPath}"
          echo "With environment args: ${setEnvArgs}"
          
          ${pkgs.systemd}/bin/systemd-run \
            --machine=${lib.escapeShellArg job.user}@.host \
            --user \
            --unit=rsync-user-script-runner-${jobName} \
            --collect \
            --wait \
            ${setEnvArgs} \
            ${userScriptPath}

          JOB_EXIT_CODE=$?
          if [ $JOB_EXIT_CODE -ne 0 ]; then
            echo "ERROR: User script execution failed with exit code $JOB_EXIT_CODE for job '${jobName}'." >&2
          else
            echo "User script execution completed successfully for job '${jobName}'."
          fi

          echo "Cleaning up temporary directory ${tempCopyDir}..."
          ${pkgs.coreutils}/bin/rm -rf "${tempCopyDir}"
          echo "System service for rsync copy job '${jobName}': Preparation and trigger complete."
          exit $JOB_EXIT_CODE
        '';
      in
      lib.nameValuePair systemServiceName {
        description = "Rsync Copy preparation stage for job " + jobName;
        serviceConfig = { Type = "oneshot"; User = "root"; Group = "root"; ExecStart = systemExecScript; PrivateTmp = true; };
      }
    ) cfg.jobs;

    systemd.timers = lib.mapAttrs' (jobName: job:
      lib.nameValuePair "rsync-copy-job-${jobName}" {
        description = "Timer for Rsync Copy job ${jobName}";
        timerConfig = { OnCalendar = job.startAt; Persistent = job.persistentTimer; Unit = "rsync-copy-prepare-${jobName}.service"; };
        wantedBy = [ "timers.target" ];
      }
    ) cfg.jobs;
    # No user service template needed here anymore
  };
}