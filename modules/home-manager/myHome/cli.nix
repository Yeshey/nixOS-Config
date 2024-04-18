{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.cli;
in
{
  options.myHome.cli = {
    enable = (lib.mkEnableOption "cli") // { default = true; };
    personalGit.enable = (lib.mkEnableOption "personalGitEnable") // { default = true; };
    personalGit.userName = lib.mkOption {
      type = lib.types.str;
      default = "Yeshey";
    };
    personalGit.userEmail = lib.mkOption {
      type = lib.types.str;
      default = "yesheysangpo@hotmail.com";
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      zsh.shellAliases = {
        lg = "lazygit";
      };
      git = {
        enable = true;
        userName = lib.mkIf cfg.personalGit.enable "${cfg.personalGit.userName}";
        userEmail = lib.mkIf cfg.personalGit.enable "${cfg.personalGit.userEmail}";
      };
    };
    home.packages = with pkgs; [
      neofetch
      yt-dlp # download youtube videos
      scrcpy # screen cast android phone
      ocrmypdf
      libnotify # so you can use notify-send

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
