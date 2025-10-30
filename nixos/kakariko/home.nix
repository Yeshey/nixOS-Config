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
      zed-editor.enable = true;
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
      wallpaper = pkgs.wallpapers.tunaCoimbra2025; # johnKearneyCityscapePoster #nierAutomataWallpaper #stellarCollisionByKuldarleement #tunaCoimbra2025
      cursor = {
        package = pkgs.banana-cursor;
        name = "Banana";
        size = 24;
      };
    };
    #agenix = {
    #  enable = true;
    #  sshKeys.enable = true;
    #};
    impermanence.enable = false;
    #autosshReverseProxy = {
    #  enable = true;
    #  remoteIP = "143.47.53.175";
    #  remoteUser = "yeshey";
    #  port = 2333;
    #};
    warnElections.enable = true;
    desktopItems = {
      xrdp = {
        enable = true;
        remote.ip = "143.47.53.175";
        remote.user = "yeshey";
        extraclioptions = "/p: /w:1920 /h:1080 /smart-sizing /audio-mode:1 /clipboard /network:modem /compression";
      };
      openvscodeServer = {
        enable = true;
        vpn = {
          enable = true;
        };
        port = 2998;
        remote = "oracle";
      };
    };
    nh.enable = true;
  };

  home = {
    # Specific packages
    packages = with pkgs; [
      nethack
      resources # (better system monitor) (or missioncenter), bc psensor is unmaintained

      # draw
      unstable.joplin-desktop
      rnote

      # Surface and Desktop apps
      qbittorrent
      blender # for blender
      gimp
      darktable
      krita
      inkscape
    ];
  };

}
