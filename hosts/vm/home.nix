#
#  Home-manager configuration for desktop
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
{

  home = {                                # Specific packages
    packages = with pkgs; [
    ];
  };

    # Make some folders not sync please
    home.file = {
      "${shortenedPath}/PersonalFiles/2023/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
      "${shortenedPath}/PersonalFiles/2022/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
      "${shortenedPath}/PersonalFiles/Timeless/Syncthing/PhoneCamera/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
      "${shortenedPath}/PersonalFiles/Timeless/Syncthing/Allsync/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
      "${shortenedPath}/PersonalFiles/Timeless/Music/.stignore".source = builtins.toFile ".stignore" ''
*
          '';
    };

  # Github PlasmaManager Repo: https://github.com/pjones/plasma-manager
  # got with this command: nix run github:pjones/plasma-manager > plasmaconf.nix
  # Not working yet, keep an eye on it.
  # programs.plasma5 = import ./nixFiles/plasmaconf.nix;

  # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
#  home.file.".config/user-dirs.dirs".source = builtins.toFile "user-dirs.dirs" ''
#XDG_DESKTOP_DIR="$HOME/Desktop"
#XDG_DOWNLOAD_DIR="/mnt/DataDisk/Downloads/"
#XDG_TEMPLATES_DIR="$HOME/Templates"
#XDG_PUBLICSHARE_DIR="$HOME/Public"
#XDG_DOCUMENTS_DIR="/mnt/DataDisk/PersonalFiles/"
#XDG_MUSIC_DIR="/mnt/DataDisk/PersonalFiles/Timeless/Music/"
#XDG_PICTURES_DIR="$HOME/Pictures"
#XDG_VIDEOS_DIR="$HOME/Videos"
#  '';

}
