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
  onedriverPackage = pkgs.myOnedriver; #  when you change this, change the package in agenix onedriver as well check if the latest version works already, currently its a grey screen https://github.com/jstaf/onedriver/issues/398
  #onedriverPackage = pkgs.unstable.onedriver;

  # Using my package this shouldn't be needed anymore in the system config:
  # environment.variables.GIO_EXTRA_MODULES = lib.mkOverride 1010 [ "${pkgs.glib-networking.out}/lib/gio/modules" ]; # needed for now for onedriver (made an issue: https://github.com/NixOS/nixpkgs/issues/308666)

  # check my issue on it: https://github.com/NixOS/nixpkgs/issues/308666

in
{
  options.myHome.onedriver = with lib; {
    enable = mkEnableOption "onedriver";
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
    serviceName = "onedriver@" + config.myHome.onedriver.serviceCoreName + ".service";
  in lib.mkIf (config.myHome.enable && cfg.enable) {

    home.packages = [
      onedriverPackage
    ];

    # Make sure mountpoint folder exists
    systemd.user.services."mountpoint-folder-onedriver" = let
      script = pkgs.writeShellScriptBin "mountpoint-folder-onedriver-script" ''
          mkdir -p '${cfg.onedriverFolder}' 
        '';
    in {
      Unit = {
        Description = "mountpoint-folder-onedriver";
      };
      Service = { 
        Type = "oneshot";
        ExecStart = "${script}/bin/mountpoint-folder-onedriver-script";
        #ExecStart = "mkdir -p '${cfg.onedriverFolder}' "; # "${mystuff}/bin/doyojob";
      };
      Install.WantedBy = [ "default.target" ]; # makes it start on every boot
    };

    # Automount Onedriver
    # doesnt work without a DE, for the server if you run xfreerdp and restart the service it will work
    systemd.user.services."onedriver@${serviceName}" = let
      wrapperDir = "/run/wrappers"; 
      # I hate it so much that I-m waiting for network like this bc there in no fucking way to make it work with After in a systemd user service
      waitForNetwork = pkgs.writeShellScriptBin "wait_for_network" ''
            until ${pkgs.iputils}/bin/ping -c1 google.com ; do ${pkgs.coreutils}/bin/sleep 5 ; done
          '';
    in {
    #= let
      #wrapperDir = "/run/wrappers/";
      # serviceName = builtins.exec "${pkgs.systemd}/bin/systemd-escape --template onedriver@.service --path ${cfg.onedriverFolder}";
    #in {

      #"onedriver@mnt-hdd\\x2dbtrfs-Yeshey-OneDriver" = {
      #"onedriver@home-yeshey-OneDriver" = {
      #serviceName = {

        Unit = {
          Description = "onedriver";
          After = ["onedriverAgenixYeshey.service" "network.target" "network-online.target" ];
          #Wants = [ "network-online.target" ];
          #Requires = [ "network-online.target" ];
          #After = [ "onedriverAgenixYeshey.service" ]; # "onedriver@mnt-hdd\x2dbtrfs-Yeshey-OneDriver.service"]; # "onedriver@${config.myHome.onedriver.serviceName}" ];
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
          WantedBy = [ "default.target" ]; # "graphical-session.target" ]; default.target
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
        # Before = ["onedriverAgenixYeshey"]; # idk if this does anything
      };
      Service = { 
        Type = "oneshot";
        #ExecStart = "${onedriverPackage}/bin/onedriver --wipe-cache"; # "${mystuff}/bin/doyojob";
        ExecStart = "${script}/bin/delete-onedriver-cache-script"; # "${mystuff}/bin/doyojob";
      };
      # Install.WantedBy = [ "graphical-session.target" ]; # "default.target" ]; # makes it start on every boot
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