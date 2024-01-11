{ pkgs, lib, dataStoragePath, ... }:

let
  shortenedPath = lib.strings.removePrefix "~/" dataStoragePath; # so "~/Documents" becomes "Documents"
in
{

  home = {                                # Specific packages
    packages = with pkgs; [
      texlive.combined.scheme-full
      
      # osu-lazer
      gcc
    ];
  };

  programs = {
    # general terminal shell config for all users
    zsh = {
      oh-my-zsh = {
        theme = lib.mkForce "robbyrussell"; # robbyrussell # agnoster # frisk
      };
    };
  };

    # Make some folders not sync please
    home.file = {
      "${shortenedPath}/PersonalFiles/2023/.stignore".source = builtins.toFile ".stignore" ''
//*
//Photos&Videos
          '';
#      "${shortenedPath}/PersonalFiles/2022/.stignore".source = builtins.toFile ".stignore" ''
#//*
#          '';
      "${shortenedPath}/PersonalFiles/Timeless/Syncthing/PhoneCamera/.stignore".source = builtins.toFile ".stignore" ''
//*
          '';
      "${shortenedPath}/PersonalFiles/Timeless/Syncthing/Allsync/.stignore".source = builtins.toFile ".stignore" ''
//*
watch
          '';
      "${shortenedPath}/PersonalFiles/Timeless/Music/.stignore".source = builtins.toFile ".stignore" ''
//*
AllMusic
          '';
    };
}
