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

      yt-dlp # download youtube videos
      gimp
      inkscape

      # Libreoffice
      libreoffice-qt
      hunspell
      hunspellDicts.uk_UA

    ];
  };

}
