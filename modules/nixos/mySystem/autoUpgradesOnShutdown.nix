{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.autoUpgradesOnShutdown;
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
      description = ''
        how frequently to update
      '';
    };
  };

  config = lib.mkIf cfg.enable {

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
        OnCalendar = "Fri *-*-* 20:00:00"; # Every Friday at 19:00
        Unit = "my-nixos-upgrade.service";
      };
    };
    systemd.services.my-nixos-upgrade = {
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

      preStop = 
        let
          nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
          date     = "${pkgs.coreutils}/bin/date";
          readlink = "${pkgs.coreutils}/bin/readlink";
          shutdown = "${config.systemd.package}/bin/shutdown";
          flake = "${cfg.location}#${cfg.host}";
        in 
        lib.mkForce # makes it override the script, instead of appending
        ''
          if ! systemctl list-jobs | egrep -q 'reboot.target.*start'; then
            echo "will poweroff, not reboot, upgrading..."
            
            
            echo "grabbing latest version of repo"            
            ${pkgs.busybox}/bin/su yeshey -c '${pkgs.git}/bin/git -C "${cfg.location}" pull'
            echo "Trying to upgrade all flake inputs"
            nix flake update ${cfg.location}
            ${nixos-rebuild} switch --flake ${flake} || 
              (
                echo "Upgrading all flake inputs failed, rolling back flake.lock..."
                ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock

                echo "Trying to upgrade only nixpkgs, home-manager and nixos-hardware"
                ${nixos-rebuild} switch --flake ${flake} --update-input nixpkgs --update-input home-manager --update-input nixos-hardware || 
                  (
                    echo "Upgrading nixpkgs, home-manager and nixos-hardware inputs failed, rolling back flake.lock..."
                    ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock

                    echo "Trying to upgrade only nixpkgs and home-manager"
                    ${nixos-rebuild} switch --flake ${flake} --update-input nixpkgs --update-input home-manager || 
                      (
                        echo "Upgrading nixpkgs and home-manager inputs failed, rolling back flake.lock..."
                        ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock

                        echo "Trying to upgrade only nixpkgs"
                        ${nixos-rebuild} switch --flake ${flake} --update-input nixpkgs || 
                          (
                            echo "Errors encountered, no upgrade possible, rolling back flake.lock..."
                            ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock
                            echo "Activating previous config..."
                            ${nixos-rebuild} switch --flake ${flake}
                            exit
                          )
                      )
                  ) 
              )
              ${pkgs.git}/bin/git -C "${cfg.location}" add flake.lock &&
                (
                  ${pkgs.git}/bin/git -C "${cfg.location}" commit -m "Auto Upgrade flake.lock"
                  ${pkgs.busybox}/bin/su yeshey -c '${pkgs.git}/bin/git -C "${cfg.location}" push' # changes to user yeshey to push, which is not good
                ) || echo "no commit executed"

              # Holy shit. awk doesnt work, sed doesnt as well

              # this swaps last two commits: GIT_SEQUENCE_EDITOR="sed -i -n 'h;1n;2p;g;p'" git rebase -i HEAD~2

              # awk attempt (works, but doesnt write file in place?: gawk -i inplace '{a[NR]=$0; if ($0 ~ /^pick/) {last_pick_line = $0; last_pick_position = NR}} END {print last_pick_line; for (i=1; i<NR; i++) {if (i != last_pick_position) {print a[i]}}}' /mnt/DataDisk/Downloads/test.txt


          else
            echo "Is rebooting, not upgrading..."
            # but then I should activate the timer again right? otherwise, it will only get activated next week...
          fi
        '';
      postStop = ''
        ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock
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

  };
}
