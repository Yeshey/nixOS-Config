{ inputs, ... }:
{
  # Evaluate only the container when building this flake output.
  flake.nixosConfigurations.openclaw = {
    lib = inputs.nixpkgs.lib;
    config = inputs.self.nixosConfigurations.skyloft.config.containers.openclaw.config;
  };

  flake.modules.nixos.openclaw =
    { lib, pkgs, ... }:
    let
      checkout = "/var/lib/openclaw/home/projects/nixOS-Config";
      requests = "/var/lib/openclaw/config";
      logs = "/var/lib/openclaw/rebuild";
      profile = "/nix/var/nix/profiles/per-container/openclaw/system";
      rebuildTool = pkgs.writeShellApplication {
        name = "openclaw-rebuild";
        runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.util-linux ];
        text = ''
          request="$HOME/config/rebuild.request"
          status="$HOME/rebuild/status.json"
          case "''${1:-apply}" in
            apply)
              id="$("$0" request)"
              printf '%s\n' "$id" > "$HOME/last-rebuild-request"
              echo "Rebuild request: $id"
              exec "$0" wait "$id"
              ;;
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
              if [ -r "$status" ]; then
                cat "$status"
              else
                echo "No rebuild status yet. Check the host's openclaw-guest-rebuild.path unit." >&2
                exit 1
              fi
              ;;
            wait)
              id="''${2:?Usage: openclaw-rebuild wait REQUEST_ID}"
              deadline=$((SECONDS + 3900))
              while (( SECONDS < deadline )); do
                if [ -r "$status" ]; then
                  result="$(cat "$status")"
                  if jq -e --arg id "$id" \
                    '.requestId == $id and .state == "finished"' <<< "$result" >/dev/null; then
                    code="$(jq -r '.exitStatus' <<< "$result")"
                    printf '%s\n' "$result"
                    tail -n 80 "$HOME/rebuild/latest.log" || true
                    echo "Full log: $HOME/rebuild/latest.log"
                    exit "$code"
                  fi
                fi
                sleep 2
              done
              echo "Timed out waiting. Check openclaw-rebuild status and ~/rebuild/latest.log." >&2
              exit 124
              ;;
            *) echo "Usage: openclaw-rebuild {apply|request|status|wait REQUEST_ID}" >&2; exit 2 ;;
          esac
        '';
      };
    in
    {
      # The helper remains installed in every guest built from this source.
      containers.openclaw.config = {
        imports = [ ./_playground/guest.nix ];
        environment.systemPackages = [ rebuildTool ];
      };
      containers.openclaw.bindMounts."/home/openclaw/rebuild" = {
        hostPath = logs;
        isReadOnly = true;
      };

      systemd.services."container@openclaw" = {
        # Ordinary restarts retain the latest managed guest generation.
        script = lib.mkBefore ''
          profile=${profile}
          if [ -e "$profile/init" ]; then
            SYSTEM_PATH="$(${pkgs.coreutils}/bin/readlink -f "$profile")"
            export SYSTEM_PATH
          fi
        '';
        serviceConfig.ExecReload = lib.mkForce (pkgs.writeShellScript "reload-openclaw-container" ''
          exec ${pkgs.nixos-container}/bin/nixos-container run openclaw -- \
            /nix/var/nix/profiles/system/bin/switch-to-configuration test
        '');
      };

      systemd.tmpfiles.rules = [
        "d ${logs} 0755 root root -"
        "f ${requests}/rebuild.request 0600 openclaw openclaw -"
        "f ${logs}/latest.log 0644 root root -"
      ];

      systemd.services.openclaw-guest-rebuild = {
        description = "Build and activate the OpenClaw guest from its own checkout";
        after = [ "network-online.target" "container@openclaw.service" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.nix pkgs.nixos-container pkgs.coreutils pkgs.util-linux pkgs.systemd pkgs.jq ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "1h";
          StandardOutput = "append:${logs}/latest.log";
          StandardError = "append:${logs}/latest.log";
        };
        script = ''
          set -euo pipefail
          applied=false
          guest_system=""
          request_id="$(runuser -u openclaw -- cat ${requests}/rebuild.request)"
          test -n "$request_id" || { echo "No request ID. Run openclaw-rebuild apply." >&2; exit 2; }
          write_status() {
            jq -n --arg id "$request_id" --arg state "$1" --argjson code "$2" \
              --argjson applied "$applied" --arg system "$guest_system" \
              '{requestId: $id, state: $state, exitStatus: $code,
                applied: $applied, system: $system}' > ${logs}/status.json.tmp
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
          echo "=== OpenClaw guest rebuild: $(date --iso-8601=seconds); request=$request_id ==="

          test -f ${checkout}/flake.nix || {
            echo "Clone nixOS-Config into ~/projects/nixOS-Config first; see README.md." >&2
            exit 1
          }

          # Nix snapshots the local path, including uncommitted/new files.
          # Build as the agent; only profile selection and guest activation run as root.
          guest_system="$(runuser -u openclaw -- nix build \
            --out-link ${requests}/result --print-out-paths --no-update-lock-file \
            "path:${checkout}#nixosConfigurations.openclaw.config.system.build.toplevel")"
          test -x "$guest_system/bin/switch-to-configuration"
          previous="$(readlink -f ${profile})"

          activate() {
            nix-env -p ${profile} --set "$1" || return 1
            nixos-container run openclaw -- "$1/bin/switch-to-configuration" test || return 1
            active="$(nixos-container run openclaw -- readlink -f /run/current-system)" || return 1
            [ "$active" = "$1" ]
          }
          if ! activate "$guest_system"; then
            echo "Guest activation failed; attempting to restore $previous." >&2
            if ! activate "$previous"; then
              echo "Restoring the previous guest also failed; inspect the host journal." >&2
            fi
            exit 1
          fi
          applied=true
          write_status running 0

          nixos-container run openclaw -- runuser -u openclaw -- \
            env XDG_RUNTIME_DIR=/run/user/61000 \
                DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/61000/bus \
            systemctl --user start openclaw-gateway.service

          echo "Guest configuration applied: $guest_system"
          echo "Checkout preserved. No Git commit, pull, push, or host activation was performed."
        '';
      };

      systemd.paths.openclaw-guest-rebuild = {
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-tmpfiles-setup.service" ];
        unitConfig.RequiresMountsFor = [ requests logs ];
        pathConfig = {
          PathChanged = "${requests}/rebuild.request";
          Unit = "openclaw-guest-rebuild.service";
        };
      };
    };
}
