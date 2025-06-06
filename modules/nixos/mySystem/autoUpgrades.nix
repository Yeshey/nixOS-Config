{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.autoUpgrades;
in
{
  options.mySystem.autoUpgrades = {
    enable = lib.mkEnableOption "autoUpgrades";
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

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

# make it run when shuting down?
# https://www.reddit.com/r/NixOS/comments/f3twx0/upgrade_on_shutdownidle/

    /*
          # Fix & add auto Upgrades
          # Auto Upgrade
          # a guy told you in nix wiki to make auto upgrades use boot, to be atomic, meaning, that if they get interrupted it's safe. But notice this:
      $ sudo nixos-rebuild switch --flake ~/.setup#skyloft && echo "success"
      [...]
      abr 08 22:00:50 nixos-skyloft systemd[1]: podman-mineclone-server.service: Consumed 162ms CPU time, received 16.2K IP traffic, sent 4.5K IP traffic.
      warning: error(s) occurred while switching to the new configuration

      $ sudo nixos-rebuild boot --flake ~/.setup#skyloft && echo "success"
      [...]
      warning: Git tree '/home/yeshey/.setup' is dirty
      success

      # this command makes a podman service fail, notice how I can detect that if fails with switch, but not with boot, if I want to detect that it fails and roll back in the automatic upgrades, I'll probably have to use switch
    */

    # check service with `sudo systemctl status nixos-upgrade`
    # run service with `sudo systemctl start nixos-upgrade.service`
    system.autoUpgrade = {
      enable = lib.mkOverride 1010 true;
      # dates = "23:01";
      dates = cfg.dates; #weekly
      operation = "switch";
      flake = "${cfg.location}#${cfg.host}"; # my flake online uri is for example github:yeshey/nixos-config#laptop
      flags = [
        # "--upgrade --option fallback false --update-input nixos-hardware --update-input home-manager --update-input nixpkgs || (cd ${location} && git checkout --flake.lock)"

        # "--upgrade" (seems to be redundant) # upgrade NixOS to the latest version in your chosen channel
        # "--option fallback false" # fallback false should force it to use pre-built packages (https://github.com/NixOS/nixpkgs/issues/77971)
        # "--update-input nixos-hardware --update-input home-manager --update-input nixpkgs" # To update all the packages
        # "--commit-lock-file" # commit the new lock file with git
        # || cd ${location} && git checkout -- flake.lock '' # reverts the changes to flake.lock if things went south (doesn't work because the commands in this list they aren't placed in this order in the end)
      ];
      # allowReboot = lib.mkOverride 1010 false; # set to false
      persistent = lib.mkOverride 1010 true; # upgrades even if PC was off when it would upgrade
    };
    
    /*
    # taking from https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/tasks/auto-upgrade.nix
    systemd.services.nixos-upgrade = 
      let
        cfgau = config.system.autoUpgrade;
      in
      { 
        # before = [ "shutdown.target" ]; # "reboot.target"
        script = 
          let
            nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
            date     = "${pkgs.coreutils}/bin/date";
            readlink = "${pkgs.coreutils}/bin/readlink";
            shutdown = "${config.systemd.package}/bin/shutdown";
          in 
          lib.mkForce # makes it override the script, instead of appending
          ''
            echo "grabbing latest version of repo"            
            ${pkgs.busybox}/bin/su yeshey -c '${pkgs.git}/bin/git -C "${cfg.location}" pull'
            echo "Trying to upgrade all flake inputs"
            nix flake update ${cfg.location}
            ${nixos-rebuild} ${cfgau.operation} ${toString (cfgau.flags)} || 
              (
                echo "Upgrading all flake inputs failed, rolling back flake.lock..."
                ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock

                echo "Trying to upgrade only nixpkgs, home-manager and nixos-hardware"
                ${nixos-rebuild} ${cfgau.operation} --flake ${cfgau.flake} --update-input nixpkgs --update-input home-manager --update-input nixos-hardware || 
                  (
                    echo "Upgrading nixpkgs, home-manager and nixos-hardware inputs failed, rolling back flake.lock..."
                    ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock

                    echo "Trying to upgrade only nixpkgs and home-manager"
                    ${nixos-rebuild} ${cfgau.operation} --flake ${cfgau.flake} --update-input nixpkgs --update-input home-manager || 
                      (
                        echo "Upgrading nixpkgs and home-manager inputs failed, rolling back flake.lock..."
                        ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock

                        echo "Trying to upgrade only nixpkgs"
                        ${nixos-rebuild} ${cfgau.operation} --flake ${cfgau.flake} --update-input nixpkgs || 
                          (
                            echo "Errors encountered, no upgrade possible, rolling back flake.lock..."
                            ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock
                            echo "Activating previous config..."
                            ${nixos-rebuild} ${cfgau.operation} --flake ${cfgau.flake}
                            exit
                          )
                      )
                  ) 
              )
              ${pkgs.git}/bin/git config --global --add safe.directory "${cfg.location}"
              ${pkgs.git}/bin/git config --global user.email "yesheysangpo@hotmail.com"
              ${pkgs.git}/bin/git config --global user.name "Yeshey"

              ${pkgs.git}/bin/git -C "${cfg.location}" add flake.lock &&
                (
                  ${pkgs.git}/bin/git -C "${cfg.location}" commit -m "Auto Upgrade flake.lock"
                  ${pkgs.busybox}/bin/su yeshey -c '${pkgs.git}/bin/git -C "${cfg.location}" push' # changes to user yeshey to push, which is not good
                ) || echo "no commit executed"
              
              cd ${cfg.location}/.git/objects && chown -R yeshey:users *

              # Holy shit. awk doesnt work, sed doesnt as well

              # this swaps last two commits: GIT_SEQUENCE_EDITOR="sed -i -n 'h;1n;2p;g;p'" git rebase -i HEAD~2

              # awk attempt (works, but doesnt write file in place?: gawk -i inplace '{a[NR]=$0; if ($0 ~ /^pick/) {last_pick_line = $0; last_pick_position = NR}} END {print last_pick_line; for (i=1; i<NR; i++) {if (i != last_pick_position) {print a[i]}}}' /mnt/DataDisk/Downloads/test.txt
          '';
        postStop = ''
          ${pkgs.git}/bin/git -C "${cfg.location}" checkout -- flake.lock
        '';
      };
      */
  };


    /*
    # Make the service be less CPU instensive
    systemd.services.nixos-upgrade.serviceConfig = let
      cfg = config.services.nixos-upgrade;
    in {
      # you can follow the service real time with journalctl -f -u nixos-upgrade.service
      # Also worth noting that these only apply to the physical RAM used,
      # they do not include swap space used.
      # (There is a separate MemorySwapMax setting, but no MemorySwapHigh, it seems.)
      # https://unix.stackexchange.com/questions/436791/limit-total-memory-usage-for-multiple-instances-of-systemd-service
      MemoryHigh = [ "500M" ];
      MemoryMax = [ "2048M" ];

      # https://unix.stackexchange.com/questions/494843/how-to-limit-a-systemd-service-to-play-nice-with-the-cpu
      CPUWeight = [ "20" ];
      CPUQuota = [ "85%" ];
      IOWeight = [ "20" ];
      # this doesn't work yet (https://unix.stackexchange.com/questions/441575/proper-way-to-use-onfailure-in-systemd)
      ExecStopPost= [ "sh -c 'if [ \"$$SERVICE_RESULT\" != \"success\" ]; then cd ${location} && git checkout -- flake.lock; fi'" ];
    };
    */
}
