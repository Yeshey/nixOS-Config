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

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      neofetch
      yt-dlp # download youtube videos
      scrcpy # screen cast android phone
      ocrmypdf
      libnotify # so you can use notify-send
      xdotool

      curl
      vim # The Nano editor is installed by default.
      htop
      tmux
      wget
      tree
      unzip
      unrar # also to extract .rar with ark in KDE # unrar x Lab5.rar
    ];
  };
}
