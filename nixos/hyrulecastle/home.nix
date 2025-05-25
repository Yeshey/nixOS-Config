{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:

let

in
{
  imports = [ ];

  myHome = {
    enable = true;
    # All the options
    user = "yeshey";
    # dataStoragePath = "/mnt/DataDisk"; # Needs to be set if not set in mySystem module
    xdgPersonalFilesOrganization.enable = true;
    nonNixos.enable = false;
    plasma.enable = false;
    gnome.enable = true;
    ssh.enable = true;
    hyprland = {
      enable = false;
      nvidia = false;
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
        # i2pFirefoxProfile = true; # detects automatically now, can still be toggled
      };
      webApps.enable = true;
      vscodium.enable = true;
      discord.enable = true;
      gaming.enable = true;
      kitty.enable = true;
      alacritty.enable = false;
      libreoffice.enable = true;
      devops.enable = false;
    };
    
    # autoStartApps = [ pkgs.vesktop ]; # doesnt work

    zsh = {
      enable = true;
      starshipTheme = "pinage404"; # fredericrous # pinage404
    };
    direnv.enable = true;
    
    stylix = {
      # https://www.youtube.com/watch?v=ljHkWgBaQWU
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-mirage.yaml"; #gruvbox-dark-medium #pop
      wallpaper = pkgs.wallpapers.stellarCollisionByKuldarleement; # johnKearneyCityscapePoster #nierAutomataWallpaper #stellarCollisionByKuldarleement
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
    #  port = 2232;
    #};
    warnElections.enable = true;
    desktopItems = {
      xrdp = {
        enable = true;
        remote.ip = "143.47.53.175";
        remote.user = "yeshey";
        # extraclioptions = "/w:1920 /h:1080 /smart-sizing /kbd:0x0816 /audio-mode:1 /clipboard /network:modem /compression";
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
      # Surface and Desktop apps
      # github-desktop
      # grapejuice # roblox
      
      gnome-clocks
      qbittorrent
      cheese # todo does it still work?
      p3x-onenote # might be worth trying notekit(https://github.com/blackhole89/notekit) and Zettlr(https://github.com/Zettlr/Zettlr)
      signal-desktop
      blender # for blender
      gimp
      darktable
      krita
      inkscape
      # arduino
      # premid # show youtube videos watching in discord
    ];
  };

}
