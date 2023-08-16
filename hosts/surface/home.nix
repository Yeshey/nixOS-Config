#
#  Home-manager configuration for Surface
#
#  flake.nix
#   └─ ./hosts
#       └─ ./desktop
#           └─ home.nix *
#

{ pkgs, lib, dataStoragePath, ... }:

let
  shortenedPath = lib.strings.removePrefix "~/" dataStoragePath; # so "~/Documents" becomes "Documents"
in
rec { 
  imports = [ ./configFiles/dconf.nix ]; # gnome configuration
  # Generated with: nix-shell -p dconf2nix --command "dconf dump / | dconf2nix -e --timeout 15 --verbose > dconf.nix"

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

      # For gnome
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.burn-my-windows
      gnomeExtensions.hibernate-status-button
      gnomeExtensions.tray-icons-reloaded
    ];
  };

  # Make some folders not sync please
  home.file = {
    # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
    ".config/user-dirs.dirs".source = ./configFiles/user-dirs.dirs; # nautilus configuration for surface

# These dont work because they have to be inside the home folder
#    "${shortenedPath}/PersonalFiles/2023/.stignore".source = builtins.toFile ".stignore" ''
#*
#        '';
#    "${shortenedPath}/PersonalFiles/2022/.stignore".source = builtins.toFile ".stignore" ''
#*
#        '';
#    "${shortenedPath}/PersonalFiles/Timeless/Syncthing/PhoneCamera/.stignore".source = builtins.toFile ".stignore" ''
#*
#        '';
#    "${shortenedPath}/PersonalFiles/Timeless/Syncthing/Allsync/.stignore".source = builtins.toFile ".stignore" ''
#*
#        '';
#    "${shortenedPath}/PersonalFiles/Timeless/Music/.stignore".source = builtins.toFile ".stignore" ''
#AllMusic
#        '';
  };

}
