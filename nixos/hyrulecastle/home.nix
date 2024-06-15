{
  pkgs,
  inputs,
  lib,
  ...
}:

let

in
{
  imports = [ ];

  myHome = {
    # All the options
    user = "yeshey";
    xdgPersonalFilesOrganization.enable = true;
    nonNixos.enable = false;
    plasma.enable = true;
    gnome.enable = false;
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
        i2pFirefoxProfile = true;
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
      wallpaper = pkgs.wallpapers.johnKearneyCityscapePoster; # johnKearneyCityscapePoster #nierAutomataWallpaper #stellarCollisionByKuldarleement
      cursor = {
        package = pkgs.banana-cursor;
        name = "Banana";
      };
    };

    onedriver = {
      enable = true;
      onedriverFolder = "/mnt/hdd-btrfs/Yeshey/OneDriver/";
      serviceName = "mnt-hdd\\x2dbtrfs-Yeshey-OneDriver"; 
      #enable = true;
      #onedriverFolder = "/home/yeshey/OneDriver";
      #serviceName = "home-yeshey-OneDriver";
    };

    agenix = {
      enable = true;
      sshKeys.enable = true;
      onedriver.enable = true;
    };
  };

  home = {
    # Specific packages
    packages = with pkgs; [
      # Surface and Desktop apps
      # github-desktop
      # grapejuice # roblox
      gnome.gnome-clocks
      qbittorrent
      gnome.cheese
      peek # doesn't work on wayland
      p3x-onenote # might be worth trying notekit(https://github.com/blackhole89/notekit) and Zettlr(https://github.com/Zettlr/Zettlr)
      signal-desktop
      blender # for blender
      gimp
      krita
      inkscape
      # arduino
      # premid # show youtube videos watching in discord
    ];
  };

}
