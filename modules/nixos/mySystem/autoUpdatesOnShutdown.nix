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
      default = "*-*-1/3"; # every 3 days
      description = ''
        How frequently to update (systemd calendar format)
      '';
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    environment.systemPackages = with pkgs; [
      libnotify
      notify-send-all
    ];

    # Use a timer to activate the service that will execute preStop on shutdown and not reboot
    systemd.timers.my-nixos-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true; # If missed, run on boot
        OnCalendar = cfg.dates;
        Unit = "my-nixos-update.service";
      };
    };

    systemd.services.my-nixos-update = 
    let
      nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
      flake = "${cfg.location}#${cfg.host}";
      operation = "boot"; # switch doesn't work, gets stuck in `setting up tmpfiles`
      
      updateScript = pkgs.writeShellScriptBin "nixos-update-flake" ''
        echo "Upgrading NixOS from ${flake}..."
        ${nixos-rebuild} ${operation} --flake ${flake} --refresh
        echo "Update completed successfully"
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
        ${notify-send-all}/bin/notify-send-all -u critical "Will update on shutdown..."
      '';

      preStop = ''
        FLAG_FILE="/etc/nixos-reboot-update.flag"

        if ! systemctl list-jobs | egrep -q 'poweroff.target.*start'; then
          echo "Not powering off (reboot or other), creating flag to update after reboot."
          touch $FLAG_FILE
        else
          echo "Powering off, upgrading now..."
          ${updateScript}/bin/nixos-update-flake
        fi
      '';

      unitConfig = {
        DefaultDependencies = false;  # Add this - very important!
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
      ];

      wants = [ "network-online.target" ]; # fixes a warning

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        TimeoutStopSec = "10h"; # 10 hours max
      };
    };

    # Ensure poweroff.target doesn't kill the update too early
    systemd.targets."poweroff" = {
      unitConfig = { 
        "JobTimeoutSec" = 36000; # 10h
      };
    };

    # If it rebooted instead of powering off, check for flag and update now
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