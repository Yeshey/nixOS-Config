#
#  Home-manager configuration for desktop
#
#  flake.nix
#   └─ ./hosts
#       └─ ./desktop
#           └─ home.nix *
#

{ pkgs, ... }:

{

  home = {                                # Specific packages
    packages = with pkgs; [

      gimp
      krita
      inkscape

    ];
  };

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
