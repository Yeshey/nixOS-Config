{ inputs, pkgs, lib, ... }:

let
  inherit (inputs.nix-colors) colorSchemes;
in
{ 
  myHome = {
    gnome.enable = true;
    tmux.enable = true;
    zsh.enable = true;
    homeapps.enable = true;
    neovim = {
      enable = true;
      enableLSP = true;
    };
    vscodium.enable = true;
    discord.enable = true;
    kitty.enable = true;
    alacritty.enable = true;
    colorScheme = colorSchemes.ocean; #rose-pine-moon;
    wallpaper = pkgs.wallpapers.johnKearneyCityscapePoster; #johnKearneyCityscapePoster;
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
      xdotool
      blender # for blender
      gimp
      krita
      inkscape
      premid # show youtube videos watching in discord
      # Libreoffice
      libreoffice-qt
      hunspell
      hunspellDicts.uk_UA
    ];
  };

  # Make some folders not sync please # TODO ?
  home.file = {
    # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
    ".config/user-dirs.dirs".source = ./user-dirs.dirs;
  };

  /*
    xdg = {
      enable = lib.mkDefault true;
      userDirs = {
        enable = lib.mkDefault true;
        createDirectories = lib.mkDefault true;
        desktop = lib.mkDefault "${config.home.homeDirectory}/Pulpit";
        documents = lib.mkDefault "${config.home.homeDirectory}/Dokumenty";
        download = lib.mkDefault "${config.home.homeDirectory}/Pobrane";
        music = lib.mkDefault "${config.home.homeDirectory}/Muzyka";
        pictures = lib.mkDefault "${config.home.homeDirectory}/Obrazy";
        videos = lib.mkDefault "${config.home.homeDirectory}/Wideo";
        templates = lib.mkDefault "${config.home.homeDirectory}/Szablony";
        publicShare = lib.mkDefault "${config.home.homeDirectory}/Publiczny";
      };
    };
   */

}
