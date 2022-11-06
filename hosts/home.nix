#
#  Common Home-Manager Configuration
#

{ config, lib, pkgs, user, ... }:

{ 

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";

    packages = with pkgs; [
      github-desktop
      obs-studio
      qbittorrent
      yt-dlp # download youtube videos
      anki

      # Libreoffice
      libreoffice-qt
      hunspell
      hunspellDicts.uk_UA
    ];
  };

  nixpkgs.config.allowUnfree = true;

  programs = {
    home-manager.enable = true;
  };

  home.stateVersion = "22.11";
}
