{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.cliTools;
in
{
  options.mySystem.cliTools = {
    enable = (lib.mkEnableOption "cliTools");
    personalGitEnable = (lib.mkEnableOption "personalGitEnable");
  };

  config = {
    environment.systemPackages = with pkgs; [
      nettools # ifconfig
      git
      dnsutils
      pciutils
      curl
      vim # The Nano editor is installed by default.
      tmux
      wget
      tree
      unzip
      hyfetch
      ookla-speedtest
      nh # nix helper
    ];

    programs = {
      git = {
        enable = true;
        lfs.enable = true; # makes github desktop work?
        config = {
          core = {
            "filemode" = "false"; # syncthing made file changes in git with no content
          };
        };
      };
    };
    
  };
}
