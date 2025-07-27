{
  inputs,
  pkgs,
  lib,
  dataStoragePath,
  config,
  ...
}:

let
  #shortenedPath = lib.strings.removePrefix "~/" inputs.dataStoragePath; # so "~/Documents" becomes "Documents" # TODO, what if the path didn't start with ~/ ??
  dataStoragePath = "/home/yeshey"; # TODO can u use ~?
  shortenedPath = lib.strings.removePrefix "~/" dataStoragePath; # TODO what???
in
{
  imports = [ ];

  myHome = {
    enable = true;
    # All the options
    user = "yeshey";
    nonNixos.enable = false;
    plasma.enable = false;
    gnome.enable = false;
    ssh.enable = true;
    homeApps = {
      enable = true;
      general.enable = false;
      cli = {
        enable = true;
        general.enable = true;
        git = {
          enable = true;
          personalGit = {
            enable = true;
            userName = "Yeshey";
            userEmail = "yesheysangpo@hotmail.com";
          };
        };
        tmux.enable = true;
        neovim = {
          enable = true;
        };
      };
      firefox = {
        enable = false;
        i2pFirefoxProfile = true;
      };
      vscodium.enable = true;
      discord.enable = false;
      gaming.enable = false;
      kitty.enable = false;
      alacritty.enable = false;
      libreoffice.enable = false;
      devops.enable = false;
    };
    zsh = {
      enable = true;
      starshipTheme = "fredericrous"; # fredericrous # pinage404
    };
    direnv.enable = true;
    stylix = {
      # https://www.youtube.com/watch?v=ljHkWgBaQWU
      enable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml"; #pop.yaml
      wallpaper = pkgs.wallpapers.tunaCoimbra2025; # johnKearneyCityscapePoster #nierAutomataWallpaper #stellarCollisionByKuldarleement #tunaCoimbra2025
    };
    onedriver = {
      enable = true;
      onedriverFolder = "/home/yeshey/OneDriverISEC";
      serviceCoreName = "home-yeshey-OneDriverISEC"; # real name: onedriver@home-yeshey-OneDriverISEC.service
      cliOnlyMode = true; # doesnt pop annoying windows if auth is needed again
    };
    onedriver2 = {
      enable = true;
      onedriverFolder = "/home/yeshey/OneDriverISCTE";
      serviceCoreName = "home-yeshey-OneDriverISCTE"; # real name: onedriver@home-yeshey-OneDriverISCTE.service
      cliOnlyMode = true;
    };
    agenix = {
      enable = true;
      sshKeys.enable = true;
    };
  };

  # Ignore Patterns Syncthing # Ignore Patterns Syncthing # You need to check that this doesnt override every other activation script, make lib.append? - if it was lib.mkFOrce it would override, like this it appends
  # system.userActivationScripts =
  #   let
  #   #        mkdir -p ${path}
  #       #echo "${patterns}" > ${path}/.stignore
  #     ignorePattern = path: patterns: ''
  #       mkdir -p ${path}
  #       echo "${patterns}" > ${path}/.stignore
  #     '';
  #   in
  #   {
  #     # Add ignore patters just for surface here:
  #     syncthingIgnorePatterns.text = ''
  #       # MinecraftPrismLauncherMainInstance
  #       ${ignorePattern "/home/yeshey/.local/share/PrismLauncher/instances/MainInstance/.minecraft" "
  #         // *
  #       "}
  #     '';
  #   };

  home = {
    # Specific packages # TODO check if you need these
    packages = with pkgs; [
      # texlive.combined.scheme-full
      github-desktop

      # osu-lazer
      gcc
    ];
  };
}
