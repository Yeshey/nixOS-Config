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
    dataStoragePath = "/mnt/DataDisk"; # Needs to be set in mySystem and in here (default is home folder)
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
    
  };

  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];
}
