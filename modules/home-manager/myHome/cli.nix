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
      gh.enable = true;
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
      bat
      colordiff
      curl
      file
      fzf
      htop
      jq
      neofetch
      nix-tree
      openssh
      p7zip
      ranger
      tree
      unzip
      wget
      xh
      yj
      yq
    ];
  };
}
