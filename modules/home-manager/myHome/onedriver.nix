{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.onedriver;
  #onedriverPackage = pkgs.unstable.onedriver; #pkgs.myOnedriver
  #onedriverPackage = pkgs.myOnedriver;
  #onedriverPackage = patchedPkgs.onedriver;
  onedriverPackage = pkgs.myOnedriver; # TODO check if the latest version works already, currently its a grey screen https://github.com/jstaf/onedriver/issues/398
  #onedriverPackage = pkgs.unstable.onedriver;

  # Using my package this shouldn't be needed anymore in the system config:
  # environment.variables.GIO_EXTRA_MODULES = lib.mkDefault [ "${pkgs.glib-networking.out}/lib/gio/modules" ]; # needed for now for onedriver (made an issue: https://github.com/NixOS/nixpkgs/issues/308666)

  # check my issue on it: https://github.com/NixOS/nixpkgs/issues/308666

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
          ExecStart = "${onedriverPackage}/bin/onedriver ${cfg.onedriverFolder}";
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
    systemd.user.services."delete-onedriver-cache" = let
      mystuff = pkgs.writeShellScriptBin "doyojob" ''
            ${onedriverPackage}/bin/onedriver --wipe-cache

            # FUCK THIS SHIT DOESNT WORK
            #mkdir -p "/home/yeshey/.cache/onedriver/mnt-hdd\x2dbtrfs-Yeshey-OneDriver/"
            #${pkgs.coreutils}/bin/cat ${config.age.secrets.onedriver_auth.path} > "/home/yeshey/.cache/onedriver/mnt-hdd\x2dbtrfs-Yeshey-OneDriver/auth_tokens.json" 
          '';
    in {
      Unit = {
        Description = "delete-onedriver-cache";
        #After = [ "agenix.service" ];
        #Requires = [ "agenix.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${mystuff}/bin/doyojob";
        WantedBy="onedriverAgenixYeshey.target";
      };
      # Install.WantedBy = [ "default.target" ];
    };
    systemd.user.timers."delete-onedriver-cache" = {
      Unit.Description = "delete-onedriver-cache schedule";
      Timer = {
        Unit = "delete-onedriver-cache";
        OnCalendar = "*-*-1,4,7,10,13,16,19,22,25,28"; # "*-*-1,4,7,10,13,16,19,22,25,28"; # Every three days approximatley (every minute: "*-*-* *:*:00")
        Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
      };
      Install.WantedBy = [ "timers.target" ]; # the timer starts with timers
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