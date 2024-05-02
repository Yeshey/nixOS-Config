{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.onedriver;
in
{
  options.myHome.onedriver = with lib; {
    enable = mkEnableOption "onedriver";
    onedriverFolder = mkOption {
      type = types.str;
      example = "/mnt/hdd-btrfs/Yeshey/OneDriver";
    };
  };

  config = lib.mkIf cfg.enable {

    # https://github.com/NixOS/nixpkgs/issues/291608
    # if you're here, there has to be a better way already

    # failing with TLS/SSL support not available; install glib-networking

    home.packages = with pkgs; [
      onedriver
      glib-networking
    ];

    # Automount Onedriver
    systemd.user.services = let
      wrapperDir = "/run/wrappers/";
    in {

      #"onedriver@mnt-hdd\\x2dbtrfs-Yeshey-OneDriver" = {
        "onedriver@home-yeshey-OneDriver" = {
        #shellHook = ''
        #export GIO_MODULE_DIR=${pkgs.glib-networking}/lib/gio/modules/
        #'';
        #environment = {
        #  GIO_MODULE_DIR="${pkgs.glib-networking}/lib/gio/modules/";
        #};

        Unit = {
          Description = "onedriver";
        };

        Service = {
          ExecStart = "${pkgs.onedriver}/bin/onedriver ${cfg.onedriverFolder}";
          ExecStopPost = "${wrapperDir}/bin/fusermount -uz ${cfg.onedriverFolder}";
          Restart = "on-abnormal";
          RestartSec = "3";
          RestartForceExitStatus = "2";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };

  };
}
