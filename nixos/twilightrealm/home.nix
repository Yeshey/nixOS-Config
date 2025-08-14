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
          enable = false; # pulls texlive full
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
    # autoStartApps = [ pkgs.vesktop ]; # only works with gnome??
    zsh = {
      enable = true;
      starshipTheme = "fredericrous"; # fredericrous # pinage404
    };
    direnv.enable = true;
    stylix = {
      # https://www.youtube.com/watch?v=ljHkWgBaQWU
      enable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml"; #pop.yaml
      wallpaper = pkgs.wallpapers.stellarCollisionByKuldarleement; # johnKearneyCityscapePoster #nierAutomataWallpaper #stellarCollisionByKuldarleement #tunaCoimbra2025
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
    #  port = 2233;
    #};
    warnElections.enable = false;
    desktopItems = {
      xrdp = {
        enable = true;
        remote.ip = "143.47.53.175";
        remote.user = "yeshey";
        extraclioptions = "/p: /w:1920 /h:1080 /smart-sizing /audio-mode:1 /clipboard /network:modem /compression";
      };
      openvscodeServer = {
        enable = true;
        wireguard = {
          enable = true;
          serverIP = "10.100.0.1"; # Your WireGuard server IP
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

    ];
  };

}
