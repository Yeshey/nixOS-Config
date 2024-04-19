{ pkgs, inputs, lib, ... }:

let
  inherit (inputs.nix-colors) colorSchemes;
in
{
  imports = [
  ];

  myHome = {
    user = "yeshey";
    nonNixos.enable = false;
    plasma.enable = true;
    gnome.enable = false;
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
    gaming.enable = true;
    neovim = {
      enable = true;
      enableLSP = true;
    };
    vscodium.enable = true;
    discord.enable = true;
    kitty.enable = true;
    alacritty.enable = true;
    libreoffice.enable = true;
    direnv.enable = true;
    wallpaper = pkgs.wallpapers.stellarCollisionByKuldarleement; #johnKearneyCityscapePoster #stellarCollisionByKuldarleement; #nierAutomataWallpaper;
    colorScheme = {
      theme = colorSchemes.rose-pine-moon;
      setBasedOnWallpaper = { # only takes effect if theme is not set
        enable = true;
        variant = "dark"; # or light
      };
    };

    devops.enable = false;
  };

  home = {                                # Specific packages
    packages = with pkgs; [
      # Surface and Desktop apps
      # github-desktop
      # grapejuice # roblox
      gnome.gnome-clocks
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
      arduino
      # premid # show youtube videos watching in discord
    ];
  };

  

  # Github PlasmaManager Repo: https://github.com/pjones/plasma-manager
  # got with this command: nix run github:pjones/plasma-manager > plasmaconf.nix
  # Not working yet, keep an eye on it.
  # programs.plasma5 = import ./nixFiles/plasmaconf.nix;

  # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
  home.file.".config/user-dirs.dirs".source = builtins.toFile "user-dirs.dirs" ''
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="/mnt/DataDisk/Downloads/"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="/mnt/DataDisk/PersonalFiles/"
XDG_MUSIC_DIR="/mnt/DataDisk/PersonalFiles/Timeless/Music/"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
  '';

}
