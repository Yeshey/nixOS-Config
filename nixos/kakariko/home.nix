{
  inputs,
  pkgs,
  lib,
  ...
}:

let

in
{
  myHome = {
    # All the options
    user = "yeshey";
    nonNixos.enable = false;
    plasma.enable = false;
    gnome.enable = true;
    ssh.enable = true;
    hyprland = {
      enable = false;
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
      enable = true;
      onedriverFolder = "/home/yeshey/OneDriver";
      serviceName = "home-yeshey-OneDriver";
    };
    direnv.enable = true;
    stylix = {
      # https://www.youtube.com/watch?v=ljHkWgBaQWU
      enable = true;
      #base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml"; #pop.yaml
      wallpaper = pkgs.wallpapers.nierAutomataWallpaper; # johnKearneyCityscapePoster #nierAutomataWallpaper
      cursor = {
        package = pkgs.banana-cursor;
        name = "Banana";
      };
    };
    agenix = {
      enable = true;
      sshKeys.enable = true;
      onedriver.enable = true;
    };
  };

  home = {
    # Specific packages
    packages = with pkgs; [
      psensor

      # Surface and Desktop apps
      qbittorrent
      gnome.cheese
      peek # doesn't work on wayland
      p3x-onenote # might be worth trying notekit(https://github.com/blackhole89/notekit) and Zettlr(https://github.com/Zettlr/Zettlr)
      signal-desktop
      blender # for blender
      gimp
      krita
      inkscape
    ];
  };

  xdg = {
    # for favourits in nautilus
    enable = lib.mkDefault true;
    userDirs = {
      enable = lib.mkDefault true;
      createDirectories = lib.mkDefault true;
      # desktop = lib.mkDefault "${config.home.homeDirectory}/Pulpit";
      documents = lib.mkDefault "/mnt/ntfsMicroSD-DataDisk/PersonalFiles/";
      download = lib.mkDefault "/mnt/ntfsMicroSD-DataDisk/Downloads/";
      music = lib.mkDefault "/mnt/ntfsMicroSD-DataDisk/PersonalFiles/Timeless/Music/";
      # pictures = lib.mkDefault "${config.home.homeDirectory}/Obrazy";
      # videos = lib.mkDefault "${config.home.homeDirectory}/Wideo";
      # templates = lib.mkDefault "${config.home.homeDirectory}/Szablony";
      # publicShare = lib.mkDefault "${config.home.homeDirectory}/Publiczny";
    };
  };
}
