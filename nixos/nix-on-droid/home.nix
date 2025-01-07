{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./myHome-droid.nix # can't have the inputs working
  ];
/*
  # cant pass the inputs variable inside?
  myHome = {
    enable = true;
    # All the options
    user = "nix-on-droid";
    dataStoragePath = "/data/data/com.termux.nix/files/home";
  };
*/


  myHome = {
    enable = true;
    # All the options
    user = "nix-on-droid";
    dataStoragePath = "/data/data/com.termux.nix/files/home";

    xdgPersonalFilesOrganization.enable = false;
    nonNixos.enable = false;
    #ssh.enable = true;


    homeApps = {
      enable = true;
      cli = {
        enable = true;
        general.enable = false;
        git = {
          enable = true;
          personalGit = {
            enable = true;
            userName = "Yeshey";
            userEmail = "yesheysangpo@hotmail.com";
          };
        };
        tmux.enable = false; # broken
      };
      firefox = {
        enable = false;
        i2pFirefoxProfile = true;
      };
      vscodium.enable = false;
      discord.enable = false;
      gaming.enable = false;
      kitty.enable = false;
      alacritty.enable = false;
      libreoffice.enable = false;
      devops.enable = false;
    };
    
    
    # autoStartApps = [ pkgs.vesktop ]; # only works with gnome??
    zsh = {
      enable = true;
      starshipTheme = "fredericrous"; # fredericrous # pinage404
    };

    onedriver = {
      enable = false;
      onedriverFolder = "/home/yeshey/OneDriver";
      serviceCoreName = "home-yeshey-OneDriver";
    };
    direnv.enable = true;
    #agenix = { # TODO allow to easily turn of agenix?
    #  enable = false;
    #  sshKeys.enable = true;
    #  onedriver.enable = true;
    #};
    #impermanence.enable = false;
  };

  programs.zsh = {
    shellAliases = {
      update = "nix-on-droid --flake github:Yeshey/nixOS-Config#nix-on-droid switch";
      speedtest = "speedtest-cli";
    };

    # For starting the ssh server
    initExtra = ''
      sshd-start
    '';
  };
  programs.bash = {
    initExtra = ''
      sshd-start
    '';
  };

  nix.package = pkgs.nix;

  home.packages = [
    pkgs.nix
  ];

  home.stateVersion = "24.05";
}
