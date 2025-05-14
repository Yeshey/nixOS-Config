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
      busybox
      hyfetch
      ookla-speedtest
      # yt-dlp # download youtube videos
      scrcpy # screen cast android phone
      ocrmypdf
      libnotify # so you can use notify-send
      xdotool

      nettools
      curl
      vim # The Nano editor is installed by default.
      neovim
      htop
      tmux
      wget
      tree
      btop
      #file
      unzip
    ];
  };
}
