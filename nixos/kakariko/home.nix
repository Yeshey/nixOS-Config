{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:

let

in
{
  myHome = {
    enable = true;
    # All the options
    user = "yeshey";
    xdgPersonalFilesOrganization.enable = true;
    nonNixos.enable = false;
    plasma.enable = false;
    gnome.enable = true;
    ssh.enable = true;
    hyprland = {
      enable = false;
    };
    homeApps = {
      enable = true;
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
        enable = true;
        i2pFirefoxProfile = true;
      };
      vscodium.enable = true;
      discord.enable = true;
      gaming.enable = true;
      kitty.enable = false;
      alacritty.enable = false;
      libreoffice.enable = true;
      devops.enable = false;
    };
    # autoStartApps = [ pkgs.vesktop ]; # only works with gnome??
    zsh = {
      enable = true;
      starshipTheme = "pinage404"; # fredericrous # pinage404
    };
    direnv.enable = true;
    stylix = {
      # https://www.youtube.com/watch?v=ljHkWgBaQWU
      enable = true;
      #base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/evenok-dark.yaml";
      #base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest-dark-hard.yaml";
      #base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
      wallpaper = pkgs.wallpapers.nierAutomataWallpaper; # johnKearneyCityscapePoster #nierAutomataWallpaper #stellarCollisionByKuldarleement
      cursor = {
        package = pkgs.banana-cursor;
        name = "Banana";
        size = 24;
      };
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
      cliOnlyMode = false;
    };
    agenix = {
      enable = true;
      sshKeys.enable = true;
    };
    impermanence.enable = false;
    #autosshReverseProxy = {
    #  enable = true;
    #  remoteIP = "143.47.53.175";
    #  remoteUser = "yeshey";
    #  port = 2233;
    #};
    warnElections.enable = true;
    desktopItems = {
      xrdp = {
        enable = true;
        remote.ip = "143.47.53.175";
        remote.user = "yeshey";
        extraclioptions = "/w:1920 /h:1080 /smart-sizing /audio-mode:1 /clipboard /network:modem /compression";
      };
      openvscodeServer = {
        enable = true;
        remote = "oracle";
        };
    };
  };

  home = {
    # Specific packages
    packages = with pkgs; [
      nethack
      resources # (better system monitor) (or missioncenter), bc psensor is unmaintained

      # draw
      xournal
      unstable.joplin-desktop
      rnote

      # Surface and Desktop apps
      qbittorrent
      signal-desktop
      blender # for blender
      gimp
      darktable
      krita
      inkscape
    ];
  };

}
