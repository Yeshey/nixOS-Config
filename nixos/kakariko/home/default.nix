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
    wallpaper = pkgs.wallpapers.nierWallpaper;
    /*
    builtins.fetchurl {
        url = "https://cdna.artstation.com/p/assets/images/images/018/711/480/large/john-kearney-cityscape-poster-artstation-update.jpg";
        sha256 = "sha256:01g135ydn19ci1gky48dva1pdb198dkcnpfq6b4g37zlj5vhbx9r";
      }; 
      */
  };

  home = { # Specific packages
    packages = with pkgs; [
      psensor
      lbry
      arduino

      # Surface and Desktop apps
      yt-dlp # download youtube videos
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
      arduino
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

}
