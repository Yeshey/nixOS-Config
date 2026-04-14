{
  flake.modules.nixos.upgrade-on-shutdown =
    { config, lib, pkgs, ... }:
    let
      flakeLocation = "github:yeshey/nixos-config";
      flakeAttr     = "${flakeLocation}#nixosConfigurations.${config.networking.hostName}.config.system.build.toplevel";

      # Send a desktop notification to every logged-in GUI user.
      # https://github.com/tonywalker1/notify-send-all (MIT License)
      notify-send-all = pkgs.writeShellScriptBin "notify-send-all" ''
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
            SOME_USER=$(basename "$SOME_USER")
            if [ "$SOME_USER" = 0 ]; then
                :
            else
                /run/wrappers/bin/sudo -u $(id -u -n "$SOME_USER") \
                    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/"$SOME_USER"/bus \
                    ${pkgs.libnotify}/bin/notify-send "$@"
            fi
        done

        exit 0
      '';

      # Build the system closure, set the profile, and activate via
      # switch-to-configuration boot — updates the bootloader without trying
      # to restart services, which would fail mid-shutdown.
      updateScript = pkgs.writeShellScriptBin "nixos-update-flake" ''
        set -e
        echo "Building system closure from ${flakeAttr}..."

        # 1. Build and get the store path
        OUT_PATH=$(${pkgs.nix}/bin/nix build "${flakeAttr}" --print-out-paths --no-link --refresh)

        if [ -z "$OUT_PATH" ]; then
          echo "Build failed! Aborting update."
          exit 1
        fi

        echo "Build successful: $OUT_PATH"

        # 2. Register as current generation
        echo "Setting system profile..."
        ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$OUT_PATH"

        # 3. Install bootloader only (no service restarts)
        echo "Installing bootloader..."
        export NIXOS_INSTALL_BOOTLOADER=1

        if $OUT_PATH/bin/switch-to-configuration boot; then
          echo "Bootloader installed successfully. Next boot will use the new generation."
        else
          echo "Failed to install bootloader."
          exit 1
        fi
      '';
    in
    {
      # system-desktop imports system-cli, which imports the plain `upgrade`
      # module (system.autoUpgrade.enable = true). Force it off here so only
      # the shutdown service handles upgrades on desktop machines.
      system.autoUpgrade.enable = lib.mkForce false;

      environment.systemPackages = with pkgs; [ libnotify notify-send-all ];

      # ── Timer ──────────────────────────────────────────────────────────────
      # Fires on the 1st and 16th of each month at 06:10 — 10 min after any
      # scheduled GitHub Action push. Its job is to arm the service so the
      # notification fires and the service waits for the next power-off.
      systemd.timers.my-nixos-update = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          Persistent = true;
          OnCalendar = "*-*-01,16 06:10:00";
          Unit       = "my-nixos-update.service";
        };
      };

      # ── Main service ───────────────────────────────────────────────────────
      systemd.services.my-nixos-update = {
        description      = "NixOS Update on Shutdown";
        restartIfChanged = false;

        unitConfig = {
          DefaultDependencies = false; # critical: prevents pulling in shutdown ordering
          RequiresMountsFor   = "/boot /nix/store";
          X-StopOnRemoval     = false;
        };

        # Conflicts with reboot/shutdown targets so systemd won't stop us
        # prematurely; `before` ensures we finish before the target proceeds.
        conflicts = [ "reboot.target" "shutdown.target" ];
        before    = [ "shutdown.target" ];

        after = [
          "network-online.target"
          "nss-lookup.target"
          "nix-daemon.service"
          "systemd-user-sessions.service"
          "plymouth-quit-wait.service"
          "thermald.service"
          "systemd-oomd.service"
          "systemd-timesyncd.service"
          "systemd-resolved.service"
          "dbus.service"
          "autossh-reverseProxy.service"
          "sshd.service"
          "local-fs.target"
          "fix-surface-clock.service"
        ];

        wants = [ "network-online.target" ];

        environment = config.nix.envVars // {
          inherit (config.environment.sessionVariables) NIX_PATH;
          HOME = "/root";
        } // config.networking.proxy.envVars;

        path = with pkgs; [
          coreutils
          findutils
          gnutar
          xz.bin
          gzip
          gitMinimal
          config.nix.package.out
        ];

        # ExecStart: runs when the timer fires.
        # Waits 3 min then notifies all desktop users that an update is staged.
        script = ''
          echo "Will notify in 3 seconds"
          sleep 3
          ${notify-send-all}/bin/notify-send-all -u critical "Will update on shutdown..."
        '';

        # ExecStop: runs during the shutdown sequence.
        # Distinguishes power-off from reboot: on reboot, drops a flag file so
        # the boot-time check service re-arms the update for the next shutdown.
        preStop = ''
          FLAG_FILE="/etc/nixos-reboot-update.flag"

          if ! systemctl list-jobs | grep -Eq 'poweroff.target.*start'; then
            echo "Not powering off (reboot or other). Creating flag to update after next boot."
            touch "$FLAG_FILE"
          else
            echo "Power-off detected. Checking battery/power before upgrading..."

            BATTERY=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" | sort | head -1)
            AC=$(find /sys/class/power_supply -maxdepth 1 \
                  \( -name "AC*" -o -name "ADP*" -o -name "ACAD*" \) | sort | head -1)

            if [ -n "$BATTERY" ]; then
              LEVEL=$(cat "$BATTERY/capacity")
              echo "Battery level: ''${LEVEL}%"
            else
              echo "No battery detected (desktop). Treating as always-OK."
              LEVEL=100
            fi

            PROCEED=0

            if [ "$LEVEL" -ge 85 ]; then
              echo "Battery >= 85% — proceeding with update."
              PROCEED=1
            else
              echo "Battery at ''${LEVEL}%. Waiting 60s in case power is being connected..."
              sleep 60

              ONLINE=0
              if [ -n "$AC" ]; then
                ONLINE=$(cat "$AC/online")
              fi

              if [ "$ONLINE" -eq 1 ]; then
                echo "AC adapter is connected — proceeding with update."
                PROCEED=1
              else
                echo "Battery low (''${LEVEL}%) and AC not connected. Skipping update."
                echo "Creating flag to retry update on next shutdown."
                touch "$FLAG_FILE"
              fi
            fi

            if [ "$PROCEED" -eq 1 ]; then
              if ${updateScript}/bin/nixos-update-flake; then
                echo "Update finished successfully."
                rm -f "$FLAG_FILE"
              else
                echo "Update FAILED. System will boot into the old generation."
              fi
            fi
          fi
        '';

        serviceConfig = {
          Type            = "oneshot";
          RemainAfterExit = "yes";
          TimeoutStopSec  = "10h";
          KillMode = "process";
        };
      };

      # Give the poweroff target enough headroom for the upgrade to complete.
      systemd.targets."poweroff".unitConfig.JobTimeoutSec = "10h";

      # ── Reboot flag check ──────────────────────────────────────────────────
      # If the system rebooted before a scheduled power-off update could run,
      # this service finds the flag and re-arms the update service so it waits
      # for the next shutdown.
      systemd.services.nixos-reboot-update-check = {
        description = "Check for deferred upgrade flag from last reboot";
        wantedBy    = [ "multi-user.target" ];
        after = [ "network.target" "my-nixos-update.timer" ];

        script = ''
          FLAG_FILE="/etc/nixos-reboot-update.flag"

          if [ -f "$FLAG_FILE" ]; then
            if ! systemctl is-active --quiet my-nixos-update.service; then
              echo "Re-arming my-nixos-update.service"
              systemctl start my-nixos-update.service
            fi
            rm "$FLAG_FILE"
          fi
        '';

        serviceConfig.Type = "oneshot";
      };
    };
}