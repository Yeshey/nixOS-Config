{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.cli;
in
{
  options.myHome.cli = {
    enable = (lib.mkEnableOption "cli") // { default = true; };
    personalGitEnable = (lib.mkEnableOption "personalGitEnable") // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      zsh.shellAliases = {
        lg = "lazygit";
      };
      git = {
        enable = true;
        userName = lib.mkIf cfg.personalGitEnable "Yeshey";
        userEmail = lib.mkIf cfg.personalGitEnable "yesheysangpo@hotmail.com";
      };
    };
    home.packages = with pkgs; [
      neofetch
      yt-dlp # download youtube videos

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
