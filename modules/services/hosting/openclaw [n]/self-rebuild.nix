{ inputs, ... }:
{
  # Evaluate only the container when building this flake output.
  flake.nixosConfigurations.openclaw = {
    lib = inputs.nixpkgs.lib;
    config = inputs.self.nixosConfigurations.skyloft.config.containers.openclaw.config;
  };

  flake.modules.nixos.openclaw =
    { config, lib, pkgs, ... }:
    let
      repository = "https://github.com/Yeshey/nixOS-Config.git";
      branch = "main";
      playgroundPath = "modules/services/hosting/openclaw [n]/_playground";
      checkout = "/var/lib/openclaw/home/projects/nixOS-Config";
      requests = "/var/lib/openclaw/config";
      logs = "/var/lib/openclaw/rebuild";
      profile = "/nix/var/nix/profiles/per-container/openclaw/system";
      githubAskpass = pkgs.writeShellScript "openclaw-github-askpass" ''
        case "$1" in
          Username*github.com*) printf '%s\n' x-access-token ;;
          Password*github.com*) cat "$CREDENTIALS_DIRECTORY/github" ;;
          *) exit 1 ;;
        esac
      '';
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
      sops.secrets.openclaw_github_token = {
        owner = "root";
        mode = "0400";
      };

      # The helper remains installed in every guest built from this source.
      containers.openclaw.config = {
        imports = [ ./_playground/guest.nix ];
        environment.systemPackages = [ rebuildTool ];
      };
      containers.openclaw.bindMounts."/home/openclaw/rebuild" = {
        hostPath = logs;
        isReadOnly = true;
      };

      systemd.tmpfiles.rules = [
        "d ${logs} 0755 root root -"
        "d ${logs}/publish 0700 root root -"
        "f ${requests}/rebuild.request 0600 openclaw openclaw -"
        "f ${logs}/latest.log 0644 root root -"
      ];

      systemd.services.openclaw-guest-rebuild = {
        description = "Build the OpenClaw guest and publish its applied playground";
        after = [ "network-online.target" "container@openclaw.service" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.nix pkgs.nixos-container pkgs.coreutils pkgs.util-linux pkgs.systemd pkgs.jq pkgs.git pkgs.rsync pkgs.findutils ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "1h";
          LoadCredential = [ "github:${config.sops.secrets.openclaw_github_token.path}" ];
          StandardOutput = "append:${logs}/latest.log";
          StandardError = "append:${logs}/latest.log";
        };
        script = ''
          set -euo pipefail
          applied=false
          published=false
          commit=""
          source=""
          publish_dir=""
          guest_system=""
          request_id="$(runuser -u openclaw -- cat ${requests}/rebuild.request)"
          test -n "$request_id" || { echo "No request ID. Run openclaw-rebuild apply." >&2; exit 2; }
          write_status() {
            jq -n --arg id "$request_id" --arg state "$1" --argjson code "$2" \
              --argjson applied "$applied" --arg system "$guest_system" \
              --argjson published "$published" --arg commit "$commit" --arg source "$source" \
              '{requestId: $id, state: $state, exitStatus: $code,
                applied: $applied, published: $published, commit: $commit,
                source: $source, system: $system}' > ${logs}/status.json.tmp
            chmod 0644 ${logs}/status.json.tmp
            mv ${logs}/status.json.tmp ${logs}/status.json
          }
          finish() {
            code=$?
            trap - EXIT
            if [ "$applied" = true ] && [ "$published" = false ]; then
              echo "Guest applied, but GitHub publication did not complete. See the error above." >&2
              if [ -n "$publish_dir" ]; then
                echo "Publication checkout retained on the host: $publish_dir" >&2
              fi
            fi
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

          # Build and publish the same immutable source, including new files.
          source="$(runuser -u openclaw -- nix flake metadata --json \
            --no-update-lock-file "path:${checkout}" | jq -er '.path')"
          playground="$source"/${lib.escapeShellArg playgroundPath}
          test -f "$playground/guest.nix"
          if [ -n "$(find "$playground" -name .git -print -quit)" ] || \
             [ -n "$(find "$playground" ! -type f ! -type d -print -quit)" ]; then
            echo "The playground must contain regular files/directories only, without .git or symlinks." >&2
            exit 1
          fi
          echo "Source snapshot: $source"
          guest_system="$(runuser -u openclaw -- nix build \
            --out-link ${requests}/result --print-out-paths --no-update-lock-file \
            "path:$source#nixosConfigurations.openclaw.config.system.build.toplevel")"
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

          # A separate publication checkout prevents unrelated local files,
          # staged changes, and branch commits from reaching main.
          # Failed publication checkouts remain available for recovery.
          export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0
          export GIT_ASKPASS=${githubAskpass}
          publish_dir="$(mktemp -d ${logs}/publish/request.XXXXXX)"
          git -c core.hooksPath=/dev/null clone --depth 1 --single-branch \
            --branch ${lib.escapeShellArg branch} ${lib.escapeShellArg repository} "$publish_dir"
          git -C "$publish_dir" config core.hooksPath /dev/null
          target="$publish_dir"/${lib.escapeShellArg playgroundPath}
          mkdir -p "$target"
          rsync -rlpt --delete --chmod=u+rwX "$playground/" "$target/"
          git -C "$publish_dir" add -f -A -- ${lib.escapeShellArg playgroundPath}
          if ! git -C "$publish_dir" diff --cached --quiet; then
            git -C "$publish_dir" -c user.name=OpenClaw \
              -c user.email=openclaw@skyloft.tailb6874b.ts.net \
              -c commit.gpgSign=false commit \
              -m "Update OpenClaw playground ($request_id)" \
              -m "Guest system: $guest_system" -m "Source snapshot: $source"
            commit="$(git -C "$publish_dir" rev-parse HEAD)"
            write_status running 0
            git -C "$publish_dir" -c credential.helper= push \
              origin HEAD:refs/heads/${lib.escapeShellArg branch}
          else
            commit="$(git -C "$publish_dir" rev-parse HEAD)"
            echo "The applied playground already matches GitHub; no new commit needed."
          fi
          published=true
          write_status running 0
          echo "GitHub revision: $commit"
          rm -rf -- "$publish_dir"

          nixos-container run openclaw -- runuser -u openclaw -- \
            env XDG_RUNTIME_DIR=/run/user/61000 \
                DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/61000/bus \
            systemctl --user start openclaw-gateway.service

          echo "Guest configuration applied: $guest_system"
          echo "Applied playground recorded on GitHub. Agent checkout preserved; host not activated."
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
