{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.cliTools;
in
{
  options.mySystem.cliTools = {
    enable = (lib.mkEnableOption "cliTools");
    personalGitEnable = (lib.mkEnableOption "personalGitEnable");
  };

  config = lib.mkIf cfg.enable {
    programs = {
      zsh.shellAliases = {
        lg = "lazygit";
      };
    };
    environment.systemPackages = with pkgs; [ 
      dnsutils
      pciutils
      curl
      vim # The Nano editor is installed by default.
      htop
      tmux
      wget
      tree
      unzip
    ];
  };
}
