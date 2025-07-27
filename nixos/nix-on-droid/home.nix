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
        general.enable = false; # not using because unfree license nixpkgs doesnt apply and i dont know how
        git = {
          enable = true;
          personalGit = {
            enable = true;
            userName = "Yeshey";
            userEmail = "yesheysangpo@hotmail.com";
          };
        };
        tmux.enable = true; # broken
        neovim.enable = true;
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
      update = "rm -rf ~/.cache/nix && nix-on-droid --flake github:Yeshey/nixOS-Config#nix-on-droid switch";
      clean = "nix-collect-garbage -d && nix-store --gc && echo 'Displaying stray roots:' && nix-store --gc --print-roots | egrep -v '^(/nix/var|/run/current-system|/run/booted-system|/proc|\{memory|\{censored)'";
    };

    # For starting the ssh server
    #initExtra
    initContent = ''
      sshd-start
    '';
  };
  programs.bash = {
    initExtra = ''
      sshd-start
    '';
  };

  nix.package = pkgs.nix;
  
  # give files premission to nix-on-droid, and then you can access storage through the storage symlink this creates in ~
  home.file."storage" = { 
    source = config.lib.file.mkOutOfStoreSymlink "/storage/emulated/0";
  };

  home.packages = [
    pkgs.nix
  ];

  home.stateVersion = "24.05";
}
