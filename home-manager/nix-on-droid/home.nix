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
    #./../../modules/home-manager/myHome
  ];

  # cant pass the inputs variable inside?
  myHome = {
    enable = true;
    # All the options
    user = "nix-on-droid";
    dataStoragePath = "~/";
  };

/*
  myHome = {
    enable = true;
    # All the options
    user = "yeshey";
    xdgPersonalFilesOrganization.enable = true;
    nonNixos.enable = false;
    plasma.enable = false;
    gnome.enable = true;
    ssh.enable = true;
    hyprland = {
      enable = false;
    };
    homeApps = {
      enable = false;
      cli = {
        enable = true;
        general.enable = true;
        git = {
          enable = true;
          personalGit = {
            enable = true;
            userName = "Yeshey";
            userEmail = "yesheysangpo@hotmail.com";
          };
        };
        tmux.enable = true;
        neovim = {
          enable = true;
          enableLSP = true;
        };
      };
      firefox = {
        enable = true;
        i2pFirefoxProfile = true;
      };
      vscodium.enable = true;
      discord.enable = true;
      gaming.enable = true;
      kitty.enable = false;
      alacritty.enable = false;
      libreoffice.enable = true;
      devops.enable = false;
    };
    # autoStartApps = [ pkgs.vesktop ]; # only works with gnome??
    zsh = {
      enable = true;
      starshipTheme = "pinage404"; # fredericrous # pinage404
    };
    onedriver = {
      enable = false;
      onedriverFolder = "/home/yeshey/OneDriver";
      serviceName = "home-yeshey-OneDriver";
    };
    direnv.enable = true;
    stylix = {
      # https://www.youtube.com/watch?v=ljHkWgBaQWU
      enable = true;
      #base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml"; #pop.yaml
      wallpaper = pkgs.wallpapers.nierAutomataWallpaper; # johnKearneyCityscapePoster #nierAutomataWallpaper #stellarCollisionByKuldarleement
      cursor = {
        package = pkgs.banana-cursor;
        name = "Banana";
      };
    };
    agenix = { # TODO allow to easily turn of agenix?
      enable = false;
      sshKeys.enable = true;
      onedriver.enable = true;
    };
    impermanence.enable = false;
  };*/


  # Configure home-manager
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;

    config =
      { config, lib, pkgs, ... }:
      {
        # Read the changelog before changing this value
        home.stateVersion = "24.05";

        # insert home-manager config
      };

    extraSpecialArgs = {
      inherit inputs;
    };
    sharedModules = builtins.attrValues outputs.homeManagerModules;
  };

  nix.package = pkgs.nix;

  home.packages = [
    pkgs.nix
  ];

  home.stateVersion = "24.05";
}
