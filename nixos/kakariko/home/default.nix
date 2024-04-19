{ inputs, pkgs, lib, ... }:

let
  inherit (inputs.nix-colors) colorSchemes;
in
{ 
  myHome = {
    user = "yeshey";
    nonNixos.enable = false;
    plasma.enable = false;
    gnome.enable = true;
    firefox = {
      enable = true;
      i2pFirefoxProfile = true;
    };
    cli = {
      enable = true;
      personalGit = {
        enable = true;
        userName = "Yeshey";
        userEmail = "yesheysangpo@hotmail.com";
      };
    };
    zsh = {
      enable = true;
      starshipTheme = "pinage404"; # fredericrous # pinage404
    };
    tmux.enable = true;
    homeapps.enable = true;
    neovim = {
      enable = true;
      enableLSP = true;
    };
    gaming.enable = true;
    vscodium.enable = true;
    discord.enable = true;
    kitty.enable = true;
    alacritty.enable = true;
    libreoffice.enable = true;
    direnv.enable = true;
    wallpaper = pkgs.wallpapers.johnKearneyCityscapePoster; #johnKearneyCityscapePoster #stellarCollisionByKuldarleement; #nierAutomataWallpaper;
    colorScheme = {
      # theme = colorSchemes.rose-pine-moon;
      setBasedOnWallpaper = { # only takes effect if theme is not set
        enable = true;
        variant = "dark"; # or light
      };
    };

    devops.enable = false;
  };


  home = { # Specific packages
    packages = with pkgs; [
      psensor

      # Surface and Desktop apps
      qbittorrent
      baobab
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

  # Make some folders not sync please # TODO ?
  #home.file = {
    # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
  #  ".config/user-dirs.dirs".source = ./user-dirs.dirs;
  #};

  xdg = {
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

  /*
    xdg = {
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

    XDG_DESKTOP_DIR="$HOME/Desktop"
    XDG_DOWNLOAD_DIR="/mnt/ntfsMicroSD-DataDisk/Downloads/"
    XDG_TEMPLATES_DIR="$HOME/Templates"
    XDG_PUBLICSHARE_DIR="$HOME/Public"
    XDG_DOCUMENTS_DIR="/mnt/ntfsMicroSD-DataDisk/PersonalFiles/"
    XDG_MUSIC_DIR="/mnt/ntfsMicroSD-DataDisk/PersonalFiles/Timeless/Music/"
    XDG_PICTURES_DIR="$HOME/Pictures"
    XDG_VIDEOS_DIR="$HOME/Videos"
   */

}
