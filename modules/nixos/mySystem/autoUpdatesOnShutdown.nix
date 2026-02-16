{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.autoUpdatesOnShutdown;
  notify-send-all = pkgs.writeShellScriptBin "notify-send-all" ''
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
    SOME_USER=$(basename "$SOME_USER")
    if [ "$SOME_USER" = 0 ]; then
#        echo "* Skipping root user."
        :
    else
        /run/wrappers/bin/sudo -u $(id -u -n "$SOME_USER") \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/"$SOME_USER"/bus ${pkgs.libnotify}/bin/notify-send "$@"
    fi
done

exit 0
  '';
in
{
  options.mySystem.autoUpdatesOnShutdown = {
    enable = lib.mkEnableOption "autoUpdatesOnShutdown";
    location = lib.mkOption {
      type = lib.types.str;
      example = "github:Yeshey/nixOS-Config";
      description = ''
        The flake location (e.g., github:user/repo, /path/to/config)
      '';
    };
    host = lib.mkOption {
      type = lib.types.str;
      example = "kakariko";
      description = ''
        Name of config to build
      '';
    };
    dates = lib.mkOption {
      type = lib.types.str;
      example = "weekly";
      default = "*-*-01,16 06:10:00";  # 10 minutes after GitHub Action
      description = ''
        How frequently to update (systemd calendar format)
      '';
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    environment.systemPackages = with pkgs; [ libnotify notify-send-all ];

    systemd.timers.my-nixos-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true;
        OnCalendar = cfg.dates;
        Unit = "my-nixos-update.service";
      };
    };

    systemd.services.my-nixos-update = 
    let
      flakeUri = "${cfg.location}#${cfg.host}";
      
      # Instead of 'nixos-rebuild', we manually build and switch.
      # This prevents systemd from trying to spawn a new service during shutdown.
      updateScript = pkgs.writeShellScriptBin "nixos-update-flake" ''
        set -e
        echo "Building system closure from ${flakeUri}..."
        
        # 1. Build the system and get the path (e.g., /nix/store/...-nixos-system-...)
        # We use --no-link to avoid cluttering the filesystem
        OUT_PATH=$(${pkgs.nix}/bin/nix build "${flakeUri}" --print-out-paths --no-link --refresh)

        if [ -z "$OUT_PATH" ]; then
          echo "Build failed! Aborting update."
          exit 1
        fi
        
        echo "Build successful: $OUT_PATH"
        
        # 2. Update the system profile (so 'nixos-rebuild' knows this is the current generation)
        echo "Setting system profile..."
        ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$OUT_PATH"
        
        # 3. Install the bootloader
        # We set NIXOS_INSTALL_BOOTLOADER=1 to ensure Grub/systemd-boot is updated
        echo "Installing bootloader..."
        export NIXOS_INSTALL_BOOTLOADER=1
        
        # We run the activation script directly.
        # 'boot' updates the bootloader but doesn't try to restart services (which would fail during shutdown)
        if $OUT_PATH/bin/switch-to-configuration boot; then
           echo "Bootloader installed successfully. Next boot will use this generation."
        else
           echo "Failed to install bootloader."
           exit 1
        fi
      '';
    in {
      description = "NixOS Update on Shutdown";
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      environment = config.nix.envVars // {
        inherit (config.environment.sessionVariables) NIX_PATH;
        HOME = "/root";
      } // config.networking.proxy.envVars;

      path = with pkgs; [
        coreutils
        gnutar
        xz.bin
        gzip
        gitMinimal
        config.nix.package.out
      ];

      script = ''
        echo "will notify in 3 min"
        sleep 180
        ${notify-send-all}/bin/notify-send-all -u critical "Will update on shutdown..."
      '';

      preStop = ''
        FLAG_FILE="/etc/nixos-reboot-update.flag"

        # Check if we are actually powering off
        if ! systemctl list-jobs | egrep -q 'poweroff.target.*start'; then
          echo "Not powering off (reboot or other), creating flag to update after reboot."
          touch $FLAG_FILE
        else
          echo "Powering off detected. Running update script..."
          
          # Run the update
          if ${updateScript}/bin/nixos-update-flake; then
             echo "Update finished successfully."
          else
             echo "Update FAILED. The system will boot into the old generation."
          fi
        fi
      '';

      unitConfig = {
        DefaultDependencies = false;  # Add this - very important!
        # Valid systemd syntax is a space-separated string
        RequiresMountsFor = "/boot /nix/store"; 
      };

      conflicts = [
        "reboot.target"
        "shutdown.target"
      ];

      before = [
        "shutdown.target"
      ];

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
      ];

      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        TimeoutStopSec = "10h"; # 10 hours max
      };
    };

    systemd.targets."poweroff" = {
      unitConfig = { 
        "JobTimeoutSec" = "10h"; 
      };
    };

    systemd.services.nixos-reboot-update-check = {
      description = "Check for update flag file on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      script = ''
        FLAG_FILE="/etc/nixos-reboot-update.flag"

        if [ -f "$FLAG_FILE" ]; then
          echo "$FLAG_FILE present, activating my-nixos-update.service for update on shutdown..."
          systemctl start my-nixos-update.service
          echo "Removing flag $FLAG_FILE"
          rm "$FLAG_FILE"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}