# my reddit rant on how this works: https://www.reddit.com/r/NixOS/comments/f3twx0/comment/l3rzd5f/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.autoUpgradesOnShutdown;
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
  options.mySystem.autoUpgradesOnShutdown = {
    enable = lib.mkEnableOption "autoUpgradesOnShutdown";
    gitRepo = lib.mkOption {
      default = "git@github.com:Yeshey/nixOS-Config.git";
      type = lib.types.str;
      example = "git@github.com:Yeshey/nixOS-Config.git";
      description = ''
        the ssh clone link of your configuration flake repo
      '';
    };
    host = lib.mkOption {
      type = lib.types.str;
      example = "kakariko";
      description = ''
        name of config to build
      '';
    };
    dates = lib.mkOption {
      type = lib.types.str;
      example = "weekly";
      default = "*-*-1/3"; # every 3 days
      description = ''
        how frequently to update
      '';
    };
  };

  config = let 

  in lib.mkIf (config.mySystem.enable && cfg.enable) {

    environment.systemPackages = with pkgs; [
      libnotify
      notify-send-all
    ];

    # Use a timer to activate the service that will execute preStop on shutdown and not reboot
    systemd.timers.my-nixos-upgrade = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
        OnCalendar = cfg.dates; # "Fri *-*-* 20:00:00"; # Every Friday at 19:00 "*:0/5"; # Every 5 minutes
        Unit = "my-nixos-upgrade.service";
      };
    };
    systemd.services.my-nixos-upgrade = 
    let
      nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
      date     = "${pkgs.coreutils}/bin/date";
      readlink = "${pkgs.coreutils}/bin/readlink";
      shutdown = "${config.systemd.package}/bin/shutdown";
      #flake = "${cfg.location}#${cfg.host}";
      operation = "boot"; # switch doesnt work, gets stuck in `setting up tmpfiles`
      ssh_key = "/home/yeshey/.ssh/my_identity";
      git_ssh_command = "ssh -i ${ssh_key} -o StrictHostKeyChecking=no";
    in 
    let
    gitScript = pkgs.writeShellScriptBin "update-git-repo" ''
  SSH_KEY="/home/yeshey/.ssh/my_identity"
  GIT_SSH_COMMAND="ssh -i ${ssh_key} -o StrictHostKeyChecking=no"

  echo "Cloning the latest version of the repo to /tmp/upgradeOnShutdown"
  rm -rf /tmp/upgradeOnShutdown
  ${pkgs.git}/bin/git clone -v --depth 1 ${cfg.gitRepo} /tmp/upgradeOnShutdown

  echo "Trying to upgrade (almost) all flake inputs"
  nix flake lock --update-input nixpkgs \
                  --update-input nixpkgs-unstable \
                  --update-input home-manager \
                  --update-input neovim-plugins \
                  --update-input stylix \
                  --update-input plasma-manager \
                  --update-input nurpkgs \
                  --update-input hyprland \
                  --update-input hyprland-plugins \
                  --update-input hyprland-contrib \
                  --update-input nixos-nvidia-vgpu \
                  --update-input deploy-rs \
                  --update-input agenix \
                  --update-input impermanence \
                  /tmp/upgradeOnShutdown

  ${nixos-rebuild} ${operation} --flake /tmp/upgradeOnShutdown#${cfg.host} || 
    (
      echo "Upgrading all flake inputs failed, rolling back flake.lock..."
      ${pkgs.git}/bin/git -C /tmp/upgradeOnShutdown checkout -- flake.lock

      echo "Trying to upgrade only nixpkgs, home-manager"
      ${nixos-rebuild} ${operation} --flake /tmp/upgradeOnShutdown#${cfg.host} --update-input nixpkgs --update-input home-manager || 
        (
          echo "Upgrading nixpkgs, home-manager and nixos-hardware inputs failed, rolling back flake.lock..."
          ${pkgs.git}/bin/git -C /tmp/upgradeOnShutdown checkout -- flake.lock

          echo "Trying to upgrade only nixpkgs and home-manager"
          ${nixos-rebuild} ${operation} --flake /tmp/upgradeOnShutdown#${cfg.host} --update-input nixpkgs --update-input home-manager || 
            (
              echo "Upgrading nixpkgs and home-manager inputs failed, rolling back flake.lock..."
              ${pkgs.git}/bin/git -C /tmp/upgradeOnShutdown checkout -- flake.lock

              echo "Trying to upgrade only nixpkgs"
              ${nixos-rebuild} ${operation} --flake /tmp/upgradeOnShutdown#${cfg.host} --update-input nixpkgs || 
                (
                  echo "Errors encountered, no upgrade possible, rolling back flake.lock..."
                  ${pkgs.git}/bin/git -C /tmp/upgradeOnShutdown checkout -- flake.lock
                  echo "Activating previous config..."
                  ${nixos-rebuild} ${operation} --flake /tmp/upgradeOnShutdown#${cfg.host}
                  exit
                )
            )
        ) 
    )
  ${pkgs.git}/bin/git -C /tmp/upgradeOnShutdown add flake.lock &&
    (
      ${pkgs.git}/bin/git -C /tmp/upgradeOnShutdown commit -m "Auto Upgrade flake.lock"
      ${pkgs.git}/bin/git -C /tmp/upgradeOnShutdown push
    ) || echo "no commit executed"
    '';
    in rec {
      description = "Updating NixOS on Shutdown";
      # before = [ "shutdown.target" "reboot.target" ];
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
        config.programs.ssh.package
      ];

      script = ''
        ${notify-send-all}/bin/notify-send-all -u critical "Will upgrade on shutdown..."
      '';
      preStop = ''
          FLAG_FILE="/etc/nixos-reboot-upgrade.flag"

          if ! systemctl list-jobs | egrep -q 'poweroff.target.*start'; then

            echo "will not poweroff, doing something else, making a flag to upgrade after reboot."
            # will make a flag and the service nixos-reboot-upgrade-check will read it and activate me again
            touch $FLAG_FILE

          else
            echo "Is powering off, upgrading..."
            
            ${gitScript}/bin/update-git-repo

          fi
        '';
        
      postStop = ''
        echo "Cleaning up /tmp/upgradeOnShutdown"
        rm -rf /tmp/upgradeOnShutdown
      '';
      unitConfig = {
        Conflicts="reboot.target";
      };

      wants = [
        "network-online.target"
        "nss-lookup.target"
        "nix-daemon.service"
        "systemd-user-sessions.service"
      ];

      after = [
        "network-online.target"
        "nss-lookup.target"
        "nix-daemon.service"
        "systemd-user-sessions.service"
        "plymouth-quit-wait.service"
      ];

      requires = [
        "network-online.target"
        "nss-lookup.target"
        "nix-daemon.service"
        "systemd-user-sessions.service"
      ];

      serviceConfig = rec {
        #User = "yeshey";
        Type = "oneshot";
        RemainAfterExit="yes"; # true?
        #ExecStart="${pkgs.coreutils}/bin/true";
        TimeoutStopSec="10h"; # 10 hours max, so systemd doesnt kill the process so early
        # run as a user with sudo https://stackoverflow.com/questions/36959877/using-sudo-with-execstart-systemd
      };
      #wantedBy = [ "multi-user.target" ];
    };
    # need to make sure poweroff.target doesn't kill it too.
    systemd.targets."poweroff" = {
      unitConfig = { 
        "JobTimeoutSec" = 36000; #"10h";
      };
    };

    # if it rebooted isntead of powering off, it skipped the upgrade, should upgrade now. Check the /etc/nixos-reboot-upgrade.flag
    systemd.services.nixos-reboot-upgrade-check = {
      description = "Check for upgrade flag file on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      script = ''
        FLAG_FILE="/etc/nixos-reboot-upgrade.flag"

        if [ -f "$FLAG_FILE" ]; then
          echo "$FLAG_FILE present, activating my-nixos-upgrade.service for upgrade on shutdown..."
          systemctl start my-nixos-upgrade.service
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
