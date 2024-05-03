{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.onedriver;
  onedriverPackage = pkgs.unstable.onedriver; #pkgs.myOnedriver
in
{
  options.myHome.onedriver = with lib; {
    enable = mkEnableOption "onedriver";
    onedriverFolder = mkOption {
      type = types.str;
      example = "/mnt/hdd-btrfs/Yeshey/OneDriver";
    };
    serviceName = mkOption {
      type = types.str;
      example = "onedriver@home-yeshey-OneDriver";
      description = "use `systemd-escape --template onedriver@.service --path /path/to/mountpoint` to figure out";
    };
  };

  config = lib.mkIf cfg.enable {

    home.packages = [
      onedriverPackage
    ];

    # Automount Onedriver
    systemd.user.services."${cfg.serviceName}" = {
    #= let
      #wrapperDir = "/run/wrappers/";
      # serviceName = builtins.exec "${pkgs.systemd}/bin/systemd-escape --template onedriver@.service --path ${cfg.onedriverFolder}";
    #in {

      #"onedriver@mnt-hdd\\x2dbtrfs-Yeshey-OneDriver" = {
      #"onedriver@home-yeshey-OneDriver" = {
      #serviceName = {

        Unit = {
          Description = "onedriver";
        };

        Service = {
          ExecStart = "${pkgs.onedriver}/bin/onedriver ${cfg.onedriverFolder}";
          # ExecStopPost = "${wrapperDir}/bin/fusermount -uz ${cfg.onedriverFolder}";
          Restart = "on-abnormal";
          RestartSec = "3";
          RestartForceExitStatus = "2";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };


    # A systemd timer and service to delete all the cahched files so it doesnt start taking up space
    systemd.user.services."delete-onedriver-cache" = {
      Unit.Description = "delete-onedriver-cache";
      Service = {
        Type = "oneshot";
        ExecStart = "${onedriverPackage}/bin/onedriver --wipe-cache";
      };
      Install.WantedBy = [ "default.target" ];
    };
    systemd.user.timers."delete-onedriver-cache" = {
      Unit.Description = "delete-onedriver-cache schedule";
      Timer = {
        Unit = "delete-onedriver-cache";
        OnCalendar = "*-*-1,4,7,10,13,16,19,22,25,28"; # "*-*-1,4,7,10,13,16,19,22,25,28"; # Every three days approximatley (every minute: "*-*-* *:*:00")
        Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
      };
      Install.WantedBy = [ "timers.target" ]; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
    };


  };
}

/*
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
        OnCalendar = "*-*-* *:*:00"; # every minute # "*-*-1,4,7,10,13,16,19,22,25,28"; # Every three days approximatley
        Unit = "delete-onedriver-cache schedule";
      };




            script = ''
              ${onedriverPackage}/bin/onedriver --wipe-cache
            '';
            serviceConfig = {
              Type = "oneshot";
              User = "${config.mySystem.user}";
            };
 */