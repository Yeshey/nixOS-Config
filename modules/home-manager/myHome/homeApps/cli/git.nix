{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.cli.git;
in
{
  options.myHome.homeApps.cli.git = {
    enable = (lib.mkEnableOption "git") // {
      default = true;
    };
    personalGit.enable = (lib.mkEnableOption "personalGitEnable") // {
      default = true;
    };
    personalGit.userName = lib.mkOption {
      type = lib.types.str;
      default = "Yeshey";
    };
    personalGit.userEmail = lib.mkOption {
      type = lib.types.str;
      default = "yesheysangpo@hotmail.com";
    };
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && config.myHome.homeApps.cli.enable && cfg.enable) {
    programs = {
      zsh.shellAliases = {
        lg = "lazygit";
      };
      git = {
        enable = true;
        userName = lib.mkIf cfg.personalGit.enable "${cfg.personalGit.userName}";
        userEmail = lib.mkIf cfg.personalGit.enable "${cfg.personalGit.userEmail}";
        # fix github desktop error
        lfs.enable = true; 
      };
    };
  };
}
