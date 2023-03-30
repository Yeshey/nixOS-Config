#
#  Home-manager configuration for Surface
#
#  flake.nix
#   └─ ./hosts
#       └─ ./desktop
#           └─ home.nix *
#

{ pkgs, ... }:

rec { 
  imports = [ ./configFiles/dconf.nix ]; # gnome configuration
  # Generated with: nix-shell -p dconf2nix --command "dconf dump / | dconf2nix -e --timeout 15 --verbose > dconf.nix"

  home = {                                # Specific packages
    packages = with pkgs; [
      psensor
      lbry
      arduino

      # Browser
      firefox

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

      # For gnome
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.burn-my-windows
      gnomeExtensions.hibernate-status-button
      gnomeExtensions.tray-icons-reloaded
    ];
  };

  # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
  home.file.".config/user-dirs.dirs".source = ./configFiles/user-dirs.dirs; # nautilus configuration for surface
  
}
