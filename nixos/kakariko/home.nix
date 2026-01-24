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
    dataStoragePath = "/mnt/btrfsMicroSD-DataDisk"; # Needs to be set in mySystem and in here (default is home folder)
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
        i2pFirefoxProfile = false;
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
    zsh = {
      enable = true;
      starshipTheme = "pinage404"; # fredericrous # pinage404
    };
    #direnv.enable = false;
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
        extraclioptions = "/p: /w:1920 /h:1080 /smart-sizing /audio-mode:1 /clipboard /network:auto /compression /kbd:layout:0x0816 /gfx:AVC420 /cache:glyph:on,bitmap:on -wallpaper -menu-anims";
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
    rcloneMountHM.enable = true; # enable with rcloneMountHM-helper in default.nix
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
      unstable.gimp
      darktable
      krita
      inkscape
    ];
  };

}
