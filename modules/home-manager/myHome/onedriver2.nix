{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.onedriver2;
  onedriverPackage = pkgs.onedriver; 
in
{
  options.myHome.onedriver2 = with lib; {
    enable = mkEnableOption "onedriver2";
    onedriverFolder = mkOption {
      type = types.str;
      example = "/mnt/hdd-btrfs/Yeshey/OneDriver";
    };
    serviceCoreName = mkOption {
      type = types.str;
      example = "home-yeshey-OneDriver";
      description = "use `systemd-escape --template onedriver@.service --path /path/to/mountpoint` to figure out";
    };
  };

  config = let
    serviceName = "onedriver@" + cfg.serviceCoreName + ".service";
  in lib.mkIf (config.myHome.enable && cfg.enable) {

    home.packages = [
      onedriverPackage
    ];

    # Make sure mountpoint folder exists
    systemd.user.services."mountpoint-folder-onedriver2" = let
      script = pkgs.writeShellScriptBin "mountpoint-folder-onedriver-script" ''
          ${pkgs.coreutils}/bin/mkdir -p '${cfg.onedriverFolder}' 
        '';
    in {
      Unit = {
        Description = "mountpoint-folder-onedriver2";
      };
      Service = { 
        Type = "oneshot";
        ExecStart = "${script}/bin/mountpoint-folder-onedriver-script";
      };
      Install.WantedBy = [ "default.target" ]; # makes it start on every boot
    };

    # Automount Onedriver
    systemd.user.services."onedriver@${serviceName}" = let
      wrapperDir = "/run/wrappers"; 
      # I hate it so much that I-m waiting for network like this bc there in no fucking way to make it work with After in a systemd user service
      waitForNetwork = pkgs.writeShellScriptBin "wait_for_network" ''
            until ${pkgs.iputils}/bin/ping -c1 google.com ; do ${pkgs.coreutils}/bin/sleep 5 ; done
          '';
    in {

        Unit = {
          Description = "onedriver";
          After = ["onedriverAgenixYeshey2.service" "network.target" "network-online.target" ];

        };

        Service = {
          ExecStartPre = "${waitForNetwork}/bin/wait_for_network";
          ExecStart = "${onedriverPackage}/bin/onedriver '${cfg.onedriverFolder}'";
          ExecStopPost = "${wrapperDir}/bin/fusermount -uz '${cfg.onedriverFolder}'";
          Restart = "on-abnormal";
          RestartSec = "3";
          RestartForceExitStatus = "2";
        };

        Install = {
          WantedBy = [ "default.target" ]; 
        };
      };

    # A systemd timer and service to delete all the cached files so it doesnt start taking up space
    systemd.user.services."delete-onedriver-cache" = let
      script = pkgs.writeShellScriptBin "delete-onedriver-cache-script" ''
            ${onedriverPackage}/bin/onedriver --wipe-cache
          '';
    in {
      Unit = {
        Description = "delete-onedriver-cache";
      };
      Service = { 
        Type = "oneshot";
        ExecStart = "${script}/bin/delete-onedriver-cache-script"; # "${mystuff}/bin/doyojob";
      };
    };
    systemd.user.timers."delete-onedriver-cache" = {
      Unit.Description = "delete-onedriver-cache schedule";
      Timer = {
        Unit = "delete-onedriver-cache.service";
        OnCalendar = "*-*-1,4,7,10,13,16,19,22,25,28"; # "*-*-1,4,7,10,13,16,19,22,25,28"; # Every three days approximatley (every minute: "*-*-* *:*:00")
        Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
      };
      Install.WantedBy = [ "timers.target" ]; # the timer starts with timers
    };
    
  };
}