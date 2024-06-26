# my reddit ran on how this works: https://www.reddit.com/r/NixOS/comments/f3twx0/comment/l3rzd5f/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

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
        ${pkgs.sudo}/bin/sudo -u $(id -u -n "$SOME_USER") \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/"$SOME_USER"/bus ${pkgs.libnotify}/bin/notify-send "$@"
    fi
done

exit 0
  '';
in
{
  options.mySystem.autoUpgradesOnShutdown = {
    enable = lib.mkEnableOption "autoUpgradesOnShutdown";
    location = lib.mkOption {
      default = "github:Yeshey/nixOS-Config";
      type = lib.types.str;
      example = "/home/yeshey/.setup";
      description = ''
        path to your flake config
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

/*
    systemd.timers."test" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Unit = "test.service";
        OnCalendar = "*-*-* *:*:00"; # Run every minute
      };
    };
    */
/*
    # https://unix.stackexchange.com/questions/39226/how-to-run-a-script-with-systemd-right-before-shutdown
    systemd.services."test" = {
      # before = [ "shutdown.target" "reboot.target" ];
      preStop = ''
        echo test > /home/yeshey/Downloads/test.txt
      '';
      serviceConfig = {
        #User = "yeshey";
        Type = "oneshot";
        RemainAfterExit="true";
      };
      wantedBy = [ "multi-user.target" ];
      #wantedBy = [ "final.target" ]; # [ "shutdown.target" ];
    };*/

/*
    systemd.services."test2" = {
      #before = [ "shutdown.target" "reboot.target" ];
      after = [ "final.target" ];
      script = ''
      if [ "$(date +%u)" -eq 2 ]; then # Check if today is Tuesday (Monday is 1, Tuesday is 2, and so on)
        echo "It's tuesday!"
        echo test2 > /home/yeshey/Downloads/test2.txt
      else
        echo "Not tuesday"
      fi
      '';
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        #User = "yeshey";
        Type = "oneshot";
        #RemainAfterExit="true";
      };
      wantedBy = [ "final.target" ];
      #wantedBy = [ "final.target" ]; # [ "shutdown.target" ];
    };*/
/*
    # doesnt work, wantedBy doesnt work? idk why https://unix.stackexchange.com/questions/39226/how-to-run-a-script-with-systemd-right-before-shutdown
    systemd.services."test3" = {
      #before = [ "shutdown.target" "reboot.target" ];
      #before = [ "shutdown.target" ]; # "halt.target" 
      wantedBy = [ "shutdown.target" ];
      script = ''
        echo test3 > /home/yeshey/Downloads/test3.txt
      '';
      unitConfig = {
        Requires="network.target";
        After="network.target";
        Before="shutdown.target";
        DefaultDependencies = false;
      };
      serviceConfig = {
        #User = "yeshey";
        Type = "oneshot";
        RemainAfterExit="yes";
      };
      #wantedBy = [ "halt.target" "shutdown.target" "final.target" ]; # "final.target"
      #wantedBy = [ "final.target" ]; # [ "shutdown.target" ];
    };*/

    # https://unix.stackexchange.com/a/479048/366800
    # runs after the root filestystem is readonly_ doesnt run on reboot
    /*
    systemd.services."test4" = {
      #before = [ "shutdown.target" "reboot.target" ];
      after = [ "poweroff.target" ];
      script = ''
        echo "test4 poweroff" > /home/yeshey/Downloads/test4.txt
      '';
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        #User = "yeshey";
        Type = "oneshot";
        #RemainAfterExit="true";
      };
      wantedBy = [ "poweroff.target" ]; # runs when the root filesystem has been stopped?
      #wantedBy = [ "final.target" ]; # [ "shutdown.target" ];
    }; */

    # https://superuser.com/questions/1705683/raspberry-pi-systemd-run-script-on-shutdown-poweroff-but-not-on-restart
    # doesnt run on reboot
    /*
    systemd.services."test5" = {
      # before = [ "shutdown.target" "reboot.target" ];
      preStop = ''
        if ! systemctl list-jobs | egrep -q 'reboot.target.*start'; then
          echo "test5 poweroff" > /home/yeshey/Downloads/test5.txt
        fi
      '';
      unitConfig = {
        Conflicts="reboot.target";
      };
      serviceConfig = {
        #User = "yeshey";
        Type = "oneshot";
        RemainAfterExit="true";
      };
      wantedBy = [ "multi-user.target" ];
      #wantedBy = [ "final.target" ]; # [ "shutdown.target" ];
    }; */

    # https://unix.stackexchange.com/questions/284598/systemd-how-to-execute-script-at-shutdown-only-not-at-reboot
    /*
    systemd.services."test6" = {
      path = with pkgs; [
        coreutils
      ];

      # before = [ "shutdown.target" "reboot.target" ];
      preStop = ''
        if ! systemctl list-jobs | egrep -q 'reboot.target.*start'; then
          echo "test6 poweroff" > /home/yeshey/Downloads/test6.txt
        fi
      '';
      after = [ "network.target" ]; # will run before network turns of, bc in shutdown order is reversed
      unitConfig = {
        Conflicts="reboot.target";
      };
      serviceConfig = {
        #User = "yeshey";
        Type = "oneshot";
        ExecStart="${pkgs.coreutils}/bin/true";
        RemainAfterExit="yes";
      };
      wantedBy = [ "multi-user.target" ];
      #wantedBy = [ "final.target" ]; # [ "shutdown.target" ];
    }; */

    # Use a timer to activate the service that will execute preStop on shutdown and not reboot
    /*
    systemd.timers."test7" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
        OnCalendar = "Fri *-*-* 20:00:00"; # Every Friday at 19:00
        Unit = "test7.service";
      };
    };
    systemd.services."test7" = {
      preStop = ''
        if ! systemctl list-jobs | egrep -q 'reboot.target.*start'; then
          echo "test7 poweroff" > /home/yeshey/Downloads/test7.txt
        fi
      '';
      unitConfig = {
        Conflicts="reboot.target";
      };
      serviceConfig = {
        #User = "yeshey";
        Type = "oneshot";
        RemainAfterExit="true";
      };
      #wantedBy = [ "multi-user.target" ];
    };
    */

    # Use a timer to activate the service that will execute preStop on shutdown and not reboot
    systemd.timers.my-nixos-upgrade = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
        OnCalendar = cfg.dates; # "Fri *-*-* 20:00:00"; # Every Friday at 19:00 "*:0/5"; # Every 5 minutes
        Unit = "my-nixos-upgrade.service";
      };
    };
    systemd.services.my-nixos-upgrade = rec {
      description = "My NixOS Upgrade";
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
      preStop = 
        let
          nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
          date     = "${pkgs.coreutils}/bin/date";
          readlink = "${pkgs.coreutils}/bin/readlink";
          shutdown = "${config.systemd.package}/bin/shutdown";
          flake = "${cfg.location}#${cfg.host}";
          operation = "boot"; # switch doesnt work, gets stuck in `setting up tmpfiles`
        in 
#         lib.mkForce # makes it override the script, instead of appending
        ''
          FLAG_FILE="/etc/nixos-reboot-upgrade.flag"

          if ! systemctl list-jobs | egrep -q 'poweroff.target.*start'; then

            echo "will not poweroff, doing something else, making a flag to upgrade after reboot."
            # will make a flag and the service nixos-reboot-upgrade-check will read it and activate me again
            touch $FLAG_FILE

          else
            echo "Is powering off, upgrading..."
            # export HOME=/home/yeshey
            
            echo "grabbing latest version of repo"   
            #${pkgs.git}/bin/git config --global --add safe.directory "${cfg.location}"        
            ${pkgs.busybox}/bin/su yeshey -c '${pkgs.git}/bin/git -C "${cfg.location}" pull'
            #${pkgs.git}/bin/git -C "${cfg.location}" pull
            echo "Trying to upgrade all flake inputs"
            # nix flake update ${cfg.location}
            # I cant update --update-input nixos-hardware cuz it breaks a lot the surface
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
                          /home/yeshey/.setup/

            ${nixos-rebuild} ${operation} --flake ${flake} || 
              (
                echo "Upgrading all flake inputs failed, rolling back flake.lock..."
                ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock

                echo "Trying to upgrade only nixpkgs, home-manager"
                ${nixos-rebuild} ${operation} --flake ${flake} --update-input nixpkgs --update-input home-manager || 
                  (
                    echo "Upgrading nixpkgs, home-manager and nixos-hardware inputs failed, rolling back flake.lock..."
                    ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock

                    echo "Trying to upgrade only nixpkgs and home-manager"
                    ${nixos-rebuild} ${operation} --flake ${flake} --update-input nixpkgs --update-input home-manager || 
                      (
                        echo "Upgrading nixpkgs and home-manager inputs failed, rolling back flake.lock..."
                        ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock

                        echo "Trying to upgrade only nixpkgs"
                        ${nixos-rebuild} ${operation} --flake ${flake} --update-input nixpkgs || 
                          (
                            echo "Errors encountered, no upgrade possible, rolling back flake.lock..."
                            ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock
                            echo "Activating previous config..."
                            ${nixos-rebuild} ${operation} --flake ${flake}
                            exit
                          )
                      )
                  ) 
              )
            ${pkgs.git}/bin/git -C "${cfg.location}" add flake.lock &&
              (
                #${pkgs.git}/bin/git -C "${cfg.location}" commit -m "Auto Upgrade flake.lock"
                ${pkgs.busybox}/bin/su yeshey -c '${pkgs.git}/bin/git -C "${cfg.location}" commit -m "Auto Upgrade flake.lock"' # changes to user yeshey to push, which is not good
                ${pkgs.busybox}/bin/su yeshey -c '${pkgs.git}/bin/git -C "${cfg.location}" push' # changes to user yeshey to push, which is not good
                #${pkgs.git}/bin/git -C "${cfg.location}" push
              ) || echo "no commit executed"

            chown -R yeshey:users "${cfg.location}"

            # Holy shit. awk doesnt work, sed doesnt as well

            # this swaps last two commits: GIT_SEQUENCE_EDITOR="sed -i -n 'h;1n;2p;g;p'" git rebase -i HEAD~2

            # awk attempt (works, but doesnt write file in place?: gawk -i inplace '{a[NR]=$0; if ($0 ~ /^pick/) {last_pick_line = $0; last_pick_position = NR}} END {print last_pick_line; for (i=1; i<NR; i++) {if (i != last_pick_position) {print a[i]}}}' /mnt/DataDisk/Downloads/test.txt

          fi
        '';
        
      postStop = ''
        ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock
      '';
      unitConfig = {
        Conflicts="reboot.target";
      };
      # https://www.freedesktop.org/wiki/Software/systemd/NetworkTarget/
      #wants = [ "local-fs.target" "remote-fs.target" "network.target" "network-online.target" "nss-lookup.target" "systemd-resolved.service" ];
      #after = [ "local-fs.target" "remote-fs.target" "network.target" "network-online.target" "nss-lookup.target" "systemd-resolved.service" ]; # will run before network turns of, bc in shutdown order is reversed
      #requires = [ "local-fs.target" "remote-fs.target" "network.target" "network-online.target" "nss-lookup.target" "systemd-resolved.service" ];

      # https://www.reddit.com/r/systemd/comments/rbde3o/running_a_script_on_shutdown_that_needs_wifi/
      # With network manager, you will always need to set "let all users connect to this network", so you still have internet after logging out
      wants = [ "network-online.target" "nss-lookup.target" ]; # if one of these fails to start, my service will start anyways
      after = [ "network-online.target" "nss-lookup.target" ]; # will run before network turns of, bc in shutdown order is reversed
      requires = [ "network-online.target" "nss-lookup.target" ]; # if one of these fails to start, my service will not start

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
