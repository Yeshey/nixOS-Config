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
    # dataStoragePath = "/home/${config.home.username}"; # this is the default
    xdgPersonalFilesOrganization.enable = true;
    nonNixos.enable = false;
    plasma.enable = true;
    gnome.enable = false;
    cosmic.enable = false;
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
      kitty.enable = false;
      alacritty.enable = false;
      libreoffice.enable = true;
      devops.enable = false;
      zed-editor.enable = true;
    };

    zsh = {
      enable = true;
      starshipTheme = "pinage404"; # fredericrous # pinage404
    };
    direnv.enable = true;

    #agenix = {
    #  enable = true;
    #  sshKeys.enable = true;
    #};
    impermanence.enable = false;
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
      # Surface and Desktop apps
      # github-desktop
      # grapejuice # roblox

      gnome-clocks
      qbittorrent
      # p3x-onenote # might be worth trying notekit(https://github.com/blackhole89/notekit) and Zettlr(https://github.com/Zettlr/Zettlr)
      blender # for blender
      unstable.gimp
      darktable
      krita
      inkscape
      # arduino
      # premid # show youtube videos watching in discord
    ];
  };

}
