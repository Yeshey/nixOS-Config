# TODO files in /root/.ssh and /home/yeshey/.ssh should be put there with agenix and this config

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.autoUpgradesSurface;
in
{
  options.mySystem.autoUpgradesSurface = {
    enable = lib.mkEnableOption "autoUpgradesSurface";
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
      enable = true;
      # dates = "23:01";
      dates = cfg.dates; #weekly
      operation = "boot"; #switch
      flake = "${cfg.location}#${cfg.host}"; # my flake online uri is for example github:yeshey/nixos-config#laptop
      flags = [
        "--build-host root@192.168.1.109"
        "--verbose"
      ];
      allowReboot = false; # set to false
      persistent = true; # upgrades even if PC was off when it would upgrade
    };

    systemd.services.nixos-upgrade = 
      let
        cfgau = config.system.autoUpgrade;
      in {
        path = with pkgs; [
          busybox
          #libnotify
          #dbus
        ];

        preStart = ''
          until ${pkgs.busybox}/bin/ping -c1 192.168.1.109 ; do sleep 300 ; done
          export DISPLAY=:0
          ssh -Y yeshey@192.168.1.109 "export DISPLAY=:0 ; nix-shell -p libnotify --run \"notify-send -u critical 'Upgrading Surface...'\""

          # how THE FUCK is it so hard to send a notification to myself!!!!??
          #function notify-send() {
          #    # Detect the name of the display in use
          #    local display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"
          #
          #    # Detect the user using such display
          #    local user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)
          #
          #    # Detect the id of the user
          #    local uid=$(id -u $user)
          #
          #
          #    runuser -u $user -- env DISPLAY=$display DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus ${pkgs.libnotify}/bin/notify-send "$@"
          #    #sudo -u $user DISPLAY=$display DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus ${pkgs.libnotify}/bin/notify-send "$@"
          #}
          #notify-send -u critical 'Upgrading Surface...'
          #${pkgs.libnotify}/bin/notify-send -u critical 'Upgrading Surface...' # THIS LINE
        '';

#        script = lib.mkBefore "
# Ignore SIGTERM and SIGINT
#trap -- '' SIGINT SIGTERM
#        ";

        serviceConfig = {
          TimeoutSec=28800;
          #TimeoutStopSec="infinity";
        };

# echo -n "Waiting for host..." ; until ${pkgs.busybox}/bin/ping -c1 192.168.1.109 >/dev/null 2>&1; do sleep 60 && echo -n "." ; done

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
  };
}
