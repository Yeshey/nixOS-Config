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

    home.packages = with pkgs; [
      myOnedriver
      # onedriver
    ];

    # Automount Onedriver
    systemd.user.services = let
      wrapperDir = "/run/wrappers/";
    in {

      #"onedriver@mnt-hdd\\x2dbtrfs-Yeshey-OneDriver" = {
      "onedriver@home-yeshey-OneDriver" = {

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
