{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.cli.general;
in
{
  options.myHome.homeApps.cli.general = {
    enable = (lib.mkEnableOption "general") // {
      default = true;
    };
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && config.myHome.homeApps.cli.enable && cfg.enable) {
    home.packages = with pkgs; [
      jq
      killall
      cmatrix
      ffmpeg-full
      yt-dlp # download youtube videos
      scrcpy # screen cast android phone
      ocrmypdf
      libnotify # so you can use notify-send
      xdotool
      gh
      android-tools
      nh # nix helper

      curl
      vim # The Nano editor is installed by default.
      tmux
      wget
      tree
      btop
      file
      unzip
      #(pkgs.python311.withPackages (python-pkgs: with python-pkgs; [
      #  tensorflow
      #  pandas
      #  numpy
      #  jupyter
      #  matplotlib
      #  sympy
        #torch
      #]))
    ];

    programs.htop = {
      enable = true;
      settings = {
        header_layout="two_50_50";
        column_meters_0="LeftCPUs Memory Zram Swap";
        column_meter_modes_0="1 1 1 1";
        column_meters_1="RightCPUs Tasks LoadAverage Uptime";
        column_meter_modes_1="1 2 2 2";
        show_cpu_temperature = 1;
      };
    };
  };
}
