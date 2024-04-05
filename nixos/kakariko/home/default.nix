{ pkgs, lib, dataStoragePath, ... }:

rec { 
  imports = [ 
    ./dconf.nix 
  ];

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
  };

  home = {                                # Specific packages
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

      # For gnome # TODO put in the myHome module?
      # gnomeExtensions.clipboard-indicator
      # gnomeExtensions.burn-my-windows
      # gnomeExtensions.hibernate-status-button
      # gnomeExtensions.tray-icons-reloaded
    ];
  };

  # Make some folders not sync please # TODO ?
  home.file = {
    # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
    ".config/user-dirs.dirs".source = ./user-dirs.dirs;
  };

}
