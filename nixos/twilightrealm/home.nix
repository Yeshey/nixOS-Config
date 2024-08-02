{ pkgs, ... }:

{
  myHome = {
    enable = true;
    # All the options
    user = "yeshey";
    xdgPersonalFilesOrganization.enable = true;
    nonNixos.enable = false;
    plasma.enable = true;
    gnome.enable = false;
    hyprland = {
      enable = false;
      nvidia = false;
    };
    ssh.enable = true;
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
        i2pFirefoxProfile = false;
      };
      webApps.enable = false;
      vscodium.enable = true;
      discord.enable = true;
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
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-mirage.yaml"; #gruvbox-dark-medium #pop
      wallpaper = pkgs.wallpapers.nierAutomataWallpaper; # johnKearneyCityscapePoster #nierAutomataWallpaper #stellarCollisionByKuldarleement
      cursor = {
        package = pkgs.apple-cursor;
        name = "Apple";
      };
    };

    /*onedriver = {
      enable = true;
      onedriverFolder = "/mnt/hdd-btrfs/Yeshey/OneDriver/";
      serviceName = "mnt-hdd\\x2dbtrfs-Yeshey-OneDriver"; 
    };*/

  };

  home = {
    # Specific packages
    packages = with pkgs; [

    ];
  };

}
