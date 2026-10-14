{ inputs, ... }:
{
  # Reuse the existing guest evaluation for the native nixos-container CLI.
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
      proposals = "/var/lib/openclaw/config";
      logs = "/var/lib/openclaw/rebuild";
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
          case "''${1:-request}" in
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
              cat "$status"
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

      containers.openclaw.config.environment.systemPackages = [ rebuildTool ];

      systemd.services."container@openclaw" = {
        # Prefer the latest managed guest generation on every start.
        # Keep the declarative generation as fallback for the first boot.
        script = lib.mkBefore ''
          profile=/nix/var/nix/profiles/per-container/openclaw/system
          if [ -e "$profile/init" ]; then
            SYSTEM_PATH="$(${pkgs.coreutils}/bin/readlink -f "$profile")"
            export SYSTEM_PATH
          fi
        '';

        # This profile is mounted at /nix/var/nix/profiles/system inside the guest.
        serviceConfig.ExecReload = lib.mkForce (pkgs.writeShellScript "reload-openclaw-container" ''
          exec ${pkgs.nixos-container}/bin/nixos-container run openclaw -- \
            /nix/var/nix/profiles/system/bin/switch-to-configuration test
        '');

        # Seed once; preserve the agent's playground on later deployments.
        preStart = lib.mkBefore ''
          if [ ! -d ${proposals}/playground ]; then
            mkdir -p ${proposals}/playground
            cp -r --no-preserve=mode,ownership ${./_playground}/. ${proposals}/playground/
            if [ -f ${proposals}/guest.nix ] && [ ! -L ${proposals}/guest.nix ]; then
              ${pkgs.util-linux}/bin/runuser -u openclaw -- ${pkgs.coreutils}/bin/cat ${proposals}/guest.nix \
                > ${proposals}/playground/guest.nix
            fi
            chown -R 61000:61000 ${proposals}/playground
            chmod -R u+rwX ${proposals}/playground
          fi
          ln -sfn playground/guest.nix ${proposals}/guest.nix
        '';
      };

      # This is a normal relative module import, included in pure flake builds.
      containers.openclaw.config.imports = [ ./_playground/guest.nix ];
      containers.openclaw.bindMounts."/home/openclaw/rebuild" = {
        hostPath = logs;
        isReadOnly = true;
      };

      systemd.tmpfiles.rules = [
        "d ${logs} 0755 root root -"
        "f ${proposals}/rebuild.request 0600 openclaw openclaw -"
        "f ${logs}/latest.log 0644 root root -"
      ];

      systemd.services.openclaw-guest-rebuild = {
        description = "Update only the OpenClaw container from the latest repository and guest module";
        after = [ "network-online.target" "container@openclaw.service" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.git pkgs.nix pkgs.nixos-container pkgs.coreutils pkgs.util-linux pkgs.systemd pkgs.diffutils pkgs.jq pkgs.rsync pkgs.findutils ];
        environment.GIT_TERMINAL_PROMPT = "0";
        serviceConfig = {
          Type = "oneshot";
          RuntimeDirectory = "openclaw-guest-rebuild";
          RuntimeDirectoryMode = "0700";
          WorkingDirectory = "/run/openclaw-guest-rebuild";
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
          request_id="$(runuser -u openclaw -- cat ${proposals}/rebuild.request)"
          request_id="''${request_id:-manual}"
          write_status() {
            jq -n --arg id "$request_id" --arg state "$1" --argjson code "$2" \
              --argjson applied "$applied" --argjson published "$published" --arg commit "$commit" \
              '{requestId: $id, state: $state, exitStatus: $code,
                applied: $applied, published: $published, commit: $commit}' > ${logs}/status.json.tmp
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

          # Snapshot as the agent user, without following symlinks or copying
          # devices. Freeze the copy before building or publishing it.
          chmod 0711 .
          mkdir snapshot
          chown 61000:61000 snapshot
          runuser -u openclaw -- ${pkgs.rsync}/bin/rsync -rlpt \
            ${proposals}/playground/ snapshot/
          chown -R root:root snapshot
          chmod -R go-w snapshot
          if [ -n "$(find snapshot -mindepth 1 ! -type f ! -type d -print -quit)" ] || \
             [ -n "$(find snapshot -name .git -print -quit)" ]; then
            echo "The playground may contain only regular files and directories, without .git." >&2
            exit 1
          fi
          test -f snapshot/guest.nix
          git clone --depth 1 --single-branch --branch ${lib.escapeShellArg branch} \
            ${lib.escapeShellArg repository} source
          echo "Repository revision: $(git -C source rev-parse HEAD)"
          playground=source/${lib.escapeShellArg playgroundPath}
          test -d "$playground"
          rsync -rlpt --delete snapshot/ "$playground/"
          # Force-add the folder so new helper files are included in the build
          # and commit even when the repository has ignore patterns.
          git -C source add -f -A -- ${lib.escapeShellArg playgroundPath}

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

            applied=true
            write_status running 0

            nixos-container run openclaw -- runuser -u openclaw -- \
              env XDG_RUNTIME_DIR=/run/user/61000 \
                  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/61000/bus \
              systemctl --user start openclaw-gateway.service

            # Publish only the snapshot that passed build and activation.
            if ! git -C source diff --cached --quiet; then
              git -C source -c core.hooksPath=/dev/null \
                -c user.name="OpenClaw" \
                -c user.email="openclaw@skyloft.tailb6874b.ts.net" \
                commit -m "Update OpenClaw playground ($request_id)"
              commit="$(git -C source rev-parse HEAD)"
              if ! GIT_ASKPASS=${githubAskpass} \
                git -C source -c credential.helper= -c core.hooksPath=/dev/null \
                push origin HEAD:refs/heads/${lib.escapeShellArg branch}; then
                echo "Guest applied, but GitHub publication failed. No force-push was attempted." >&2
                exit 1
              fi
            else
              commit="$(git -C source rev-parse HEAD)"
              echo "The playground already matches GitHub; no commit is needed."
            fi
            published=true
            echo "GitHub revision: $commit"

            echo "Guest configuration applied and published successfully."
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