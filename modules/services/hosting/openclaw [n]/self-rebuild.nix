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
    in
    {
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
        path = [ pkgs.git pkgs.nix pkgs.nixos-container pkgs.coreutils pkgs.util-linux pkgs.systemd pkgs.diffutils ];
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
            systemctl reload container@openclaw.service
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