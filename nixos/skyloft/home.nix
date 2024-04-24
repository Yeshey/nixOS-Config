{
  inputs,
  pkgs,
  lib,
  dataStoragePath,
  ...
}:

let
  #shortenedPath = lib.strings.removePrefix "~/" inputs.dataStoragePath; # so "~/Documents" becomes "Documents" # TODO, what if the path didn't start with ~/ ??
  dataStoragePath = "/home/yeshey"; # TODO can u use ~?
  shortenedPath = lib.strings.removePrefix "~/" dataStoragePath; # TODO what???
in
# TODO how to inherit datastoragepath from default.nix? inherit dataStoragePath;?
{
  imports = [ ];

  myHome = {
    # All the options
    user = "yeshey";
    nonNixos.enable = false;
    plasma.enable = false;
    gnome.enable = false;
    homeApps = {
      enable = false;
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
          enableLSP = true;
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
    #wallpaper = pkgs.wallpapers.johnKearneyCityscapePoster; #johnKearneyCityscapePoster #stellarCollisionByKuldarleement; #nierAutomataWallpaper;
    #colorScheme = {
    # theme = colorSchemes.rose-pine-moon;
    #  setBasedOnWallpaper = { # only takes effect if theme is not set
    #    enable = true;
    #    variant = "dark"; # or light
    #  };
    #};
  };

  home = {
    # Specific packages # TODO check if you need these
    packages = with pkgs; [
      # texlive.combined.scheme-full
      inkscape

      # osu-lazer
      openvscode-server
      gcc
    ];
  };
}
