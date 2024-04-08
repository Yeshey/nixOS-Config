{ inputs, pkgs, lib, dataStoragePath, ... }:

let
  #shortenedPath = lib.strings.removePrefix "~/" inputs.dataStoragePath; # so "~/Documents" becomes "Documents" # TODO, what if the path didn't start with ~/ ??
  dataStoragePath = "/home/yeshey"; #TODO can u use ~?
  shortenedPath = lib.strings.removePrefix "~/" dataStoragePath; # TODO what???
  # TODO how to inherit datastoragepath from default.nix? inherit dataStoragePath;?
in
{
  imports = [ ];

  myHome = {
    # gnome.enable = true;
    tmux.enable = true;
    zsh.enable = true; # TODO make so it you comment, it should be bash
    homeapps.enable = false;
    neovim = {
      enable = true;
      enableLSP = true;
    };
    vscodium.enable = true;
  };

  home = { # Specific packages # TODO check if you need these
    packages = with pkgs; [
      # texlive.combined.scheme-full
      inkscape
      
      # osu-lazer
      openvscode-server
      gcc
    ];
  };

  programs = { # TODO does this do anything?
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
