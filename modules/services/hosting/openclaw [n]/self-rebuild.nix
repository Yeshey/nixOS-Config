{ inputs, ... }:
{
  # Reuse the existing guest evaluation for the native nixos-container CLI.
  flake.nixosConfigurations.openclaw = {
    lib = inputs.nixpkgs.lib;
    config = inputs.self.nixosConfigurations.skyloft.config.containers.openclaw.config;
  };

  flake.modules.nixos.openclaw =
    { lib, pkgs, ... }:
    let
      repository = "https://github.com/Yeshey/nixOS-Config.git";
      branch = "main";
      modulePath = "modules/services/hosting/openclaw [n]/_playground/guest.nix-data";
      proposals = "/var/lib/openclaw/config";
      logs = "/var/lib/openclaw/rebuild";
      checkout = "/home/yeshey/.setup/modules/services/hosting/openclaw [n]/_playground/guest.nix-data";
      rebuildTool = pkgs.writeShellApplication {
        name = "openclaw-rebuild";
        runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.util-linux ];
        text = ''
          request="$HOME/config/rebuild.request"
          status="$HOME/rebuild/status.json"
          case "''${1:-request}" in
            request)
              exec 9> "$HOME/config/rebuild.lock"
              flock -n 9 || { echo "Another request is being submitted." >&2; exit 1; }
              pending="$(cat "$request")"
              if [ -n "$pending" ] && { [ ! -r "$status" ] || ! jq -e --arg id "$pending" \
                '.requestId == $id and .state == "finished"' "$status" >/dev/null; }; then
                echo "A request is pending or running. Use openclaw-rebuild status." >&2
                exit 1
              fi
              id="$(cat /proc/sys/kernel/random/uuid)"
              printf '%s\n' "$id" > "$request"
              echo "$id"
              ;;
            status)
              cat "$status"
              ;;
            wait)
              id="''${2:?Usage: openclaw-rebuild wait REQUEST_ID}"
              deadline=$((SECONDS + 3900))
              while (( SECONDS < deadline )); do
                if [ -r "$status" ] && jq -e --arg id "$id" \
                  '.requestId == $id and .state == "finished"' "$status" >/dev/null; then
                  cat "$status"
                  tail -n 80 "$HOME/rebuild/latest.log"
                  exit "$(jq -r '.exitStatus' "$status")"
                fi
                sleep 2
              done
              echo "Timed out waiting. Check openclaw-rebuild status and ~/rebuild/latest.log." >&2
              exit 124
              ;;
            *) echo "Usage: openclaw-rebuild {request|status|wait REQUEST_ID}" >&2; exit 2 ;;
          esac
        '';
      };
    in
    {
      containers.openclaw.config.environment.systemPackages = [ rebuildTool ];

      # This is a normal relative module import, included in pure flake builds.
      containers.openclaw.config.imports = [ ./_playground/guest.nix-data ];
      containers.openclaw.bindMounts."/home/openclaw/rebuild" = {
        hostPath = logs;
        isReadOnly = true;
      };

      systemd.tmpfiles.rules = [
        "d ${logs} 0755 root root -"
        # C copies only when the destination does not already exist.
        "C ${proposals}/guest.nix 0640 openclaw openclaw - ${./_playground/guest.nix-data}"
        "f ${proposals}/rebuild.request 0600 openclaw openclaw -"
        "f ${logs}/latest.log 0644 root root -"
      ];

      systemd.services.openclaw-guest-rebuild = {
        description = "Update only the OpenClaw container from the latest repository and guest module";
        after = [ "network-online.target" "container@openclaw.service" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.git pkgs.nix pkgs.nixos-container pkgs.coreutils pkgs.util-linux pkgs.systemd pkgs.diffutils pkgs.jq ];
        environment.GIT_TERMINAL_PROMPT = "0";
        serviceConfig = {
          Type = "oneshot";
          RuntimeDirectory = "openclaw-guest-rebuild";
          RuntimeDirectoryMode = "0700";
          WorkingDirectory = "/run/openclaw-guest-rebuild";
          TimeoutStartSec = "1h";
          StandardOutput = "append:${logs}/latest.log";
          StandardError = "append:${logs}/latest.log";
        };
        script = ''
          set -euo pipefail
          request_id="$(runuser -u openclaw -- cat ${proposals}/rebuild.request)"
          request_id="''${request_id:-manual}"
          write_status() {
            jq -n --arg id "$request_id" --arg state "$1" --argjson code "$2" \
              '{requestId: $id, state: $state, exitStatus: $code}' > ${logs}/status.json.tmp
            chmod 0644 ${logs}/status.json.tmp
            mv ${logs}/status.json.tmp ${logs}/status.json
          }
          finish() {
            code=$?
            trap - EXIT
            write_status finished "$code"
            exit "$code"
          }
          trap finish EXIT
          trap 'exit 143' TERM
          write_status running 0
          echo "Request ID: $request_id"
          echo "=== OpenClaw guest rebuild: $(date --iso-8601=seconds) ==="

          # Read as the agent identity, then freeze this request's module bytes.
          runuser -u openclaw -- cat ${proposals}/guest.nix > guest.nix
          git clone --depth 1 --single-branch --branch ${lib.escapeShellArg branch} \
            ${lib.escapeShellArg repository} source
          echo "Repository revision: $(git -C source rev-parse HEAD)"
          test -f source/${lib.escapeShellArg modulePath}
          install -m 0644 guest.nix source/${lib.escapeShellArg modulePath}

          # path: includes the modified module, with the fetched flake.lock.
          previous=$(readlink -f /nix/var/nix/profiles/per-container/openclaw/system)
          if nixos-container update openclaw \
            --flake "path:$PWD/source#openclaw" --no-update-lock-file; then

            # Build completion alone does not prove activation. Run
            # switch-to-configuration and then verify the running generation
            # matches the built one before proceeding.
            guest_system="$(readlink -f \
              /nix/var/nix/profiles/per-container/openclaw/system)"

            nixos-container run openclaw -- \
              "$guest_system/bin/switch-to-configuration" test

            active_system="$(nixos-container run openclaw -- \
              readlink -f /run/current-system)"

            if [ "$active_system" != "$guest_system" ]; then
              echo "Guest activation failed: the running generation differs from the built generation." >&2
              exit 1
            fi

            nixos-container run openclaw -- runuser -u openclaw -- \
              env XDG_RUNTIME_DIR=/run/user/61000 \
                  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/61000/bus \
              systemctl --user start openclaw-gateway.service

            # Snapshot the exact module bytes used for this successful build
            # into Yeshey's checkout, if that checkout exists on this host.
            destination=${lib.escapeShellArg checkout}
            if [ -f "$destination" ]; then
              if cmp -s guest.nix "$destination"; then
                echo "Yeshey's checkout already matches the applied module."
              elif runuser -u yeshey -- tee "$destination" < guest.nix > /dev/null; then
                echo "Updated guest.nix-data in Yeshey's checkout."
              else
                echo "Guest updated, but copying into Yeshey's checkout failed."
              fi
            else
              echo "Guest updated; no local checkout file found to synchronize."
            fi

            echo "Guest configuration applied successfully."
          else
            echo "Update failed; restoring previous container profile."
            nix-env -p /nix/var/nix/profiles/per-container/openclaw/system --set "$previous"
            nixos-container run openclaw -- "$previous/bin/switch-to-configuration" test
            exit 1
          fi
        '';
      };

      # A deliberate request avoids rebuilding on every intermediate edit.
      systemd.paths.openclaw-guest-rebuild = {
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-tmpfiles-setup.service" ];
        unitConfig.RequiresMountsFor = [ proposals logs ];
        pathConfig = {
          PathChanged = "${proposals}/rebuild.request";
          Unit = "openclaw-guest-rebuild.service";
        };
      };
    };
}