# TODO what is this
# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

let 
  username = "yeshey";
in 
{
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "22.05";
  };

  myHome = {
    enable = true;
    # All the options
    user = "yeshey";
    dataStoragePath = "/mnt/DataDisk"; # Needs to be set if not set in mySystem module
    xdgPersonalFilesOrganization.enable = true;
    nonNixos.enable = true;
    plasma.enable = false;
    gnome.enable = true;
    ssh.enable = true;
    hyprland = {
      enable = false;
      nvidia = false;
    };

    homeApps = {
      enable = true;
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
        # i2pFirefoxProfile = true; # detects automatically now, can still be toggled
      };
      
      webApps.enable = true;
      vscodium.enable = true;
      discord.enable = true;
      gaming.enable = true;
      alacritty.enable = false;
      libreoffice.enable = false;
      

      devops.enable = false;
    };
    
    # autoStartApps = [ pkgs.vesktop ]; # doesnt work

    zsh = {
      enable = true;
      starshipTheme = "pinage404"; # fredericrous # pinage404
    };
    direnv.enable = true;
    
 #   stylix = {
      # https://www.youtube.com/watch?v=ljHkWgBaQWU
 #     enable = true;
 #     base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-mirage.yaml"; #gruvbox-dark-medium #pop
 #     wallpaper = pkgs.wallpapers.johnKearneyCityscapePoster; # johnKearneyCityscapePoster #nierAutomataWallpaper #stellarCollisionByKuldarleement
 #     cursor = {
 #       package = pkgs.banana-cursor;
 #       name = "Banana";
 #     };
 #   };
/*
    onedriver = {
      enable = true;
      onedriverFolder = "/home/yeshey/OneDriverISEC";
      serviceCoreName = "home-yeshey-OneDriverISEC"; # real name: onedriver@home-yeshey-OneDriverISEC.service
    };

    onedriver2 = {
      enable = true;
      onedriverFolder = "/home/yeshey/OneDriverISCTE";
      serviceCoreName = "home-yeshey-OneDriverISCTE"; # real name: onedriver@home-yeshey-OneDriverISEC.service
    };

    agenix = {
      enable = true;
      sshKeys.enable = true;
      onedriver = {
        enable = true;
        ageOneDriverAuthFile = config.age.secrets.onedriver_auth_isec_yeshey.path;
      };
      onedriver2 = {
        enable = true;
        ageOneDriverAuthFile = config.age.secrets.onedriver_auth_iscte_yeshey.path;
      };
    };
    impermanence.enable = false;
    */
  };

  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    #config = { # TODO remove or find a better way to use overlays?
    # Disable if you don't want unfree packages
    #  allowUnfree = true;
    #};
  };
}
