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
      };
    };

    onedriver = {
      enable = true;
      onedriverFolder = "/home/yeshey/OneDriverISEC";
      serviceCoreName = "home-yeshey-OneDriverISEC"; # real name: onedriver@home-yeshey-OneDriverISEC.service
    };

    onedriver2 = {
      enable = true;
      onedriverFolder = "/home/yeshey/OneDriverISCTE";
      serviceCoreName = "home-yeshey-OneDriverISCTE"; # real name: onedriver@home-yeshey-OneDriverISEC.service
    };

    agenix = {
      enable = true;
      sshKeys.enable = true;
      onedriver = {
        enable = true;
        ageOneDriverAuthFile = config.age.secrets.onedriver_auth_isec_yeshey.path;
      };
      onedriver2 = {
        enable = true;
        ageOneDriverAuthFile = config.age.secrets.onedriver_auth_iscte_yeshey.path;
      };
    };
    impermanence.enable = false;
    autosshReverseProxy = {
      enable = true;
      remoteIP = "143.47.53.175";
      remoteUser = "yeshey";
      port = 2222;
    };
  };

  home = {
    # Specific packages
    packages = with pkgs; [
      # Surface and Desktop apps
      # github-desktop
      # grapejuice # roblox
      
      freerdp
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
