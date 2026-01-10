{
  inputs,
  pkgs,
  lib,
  dataStoragePath,
  config,
  ...
}:

let
  #shortenedPath = lib.strings.removePrefix "~/" inputs.dataStoragePath; # so "~/Documents" becomes "Documents" # TODO, what if the path didn't start with ~/ ??
  dataStoragePath = "/home/yeshey"; # TODO can u use ~?
  shortenedPath = lib.strings.removePrefix "~/" dataStoragePath; # TODO what???
in
{
  imports = [ ];

  myHome = {
    enable = true;
    # All the options
    user = "yeshey";
    # dataStoragePath = "/home/${config.home.username}"; # this is the default
    nonNixos.enable = false;
    plasma.enable = false;
    gnome.enable = false;
    ssh.enable = true;
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
          enable = true;
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

    #agenix = {
    #  enable = false;
    #  sshKeys.enable = false;
    #};
    nh.enable = true;
    impermanence.enable = true;
  };

  # server should auto logout bc GUI uses a lot of CPU
  xdg.configFile."powerdevilrc".text = ''
[AC][RunScript]
IdleTimeoutCommand=qdbus org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout
  '';

  # Ignore Patterns Syncthing # Ignore Patterns Syncthing # You need to check that this doesnt override every other activation script, make lib.append? - if it was lib.mkFOrce it would override, like this it appends
  # system.userActivationScripts =
  #   let
  #   #        mkdir -p ${path}
  #       #echo "${patterns}" > ${path}/.stignore
  #     ignorePattern = path: patterns: ''
  #       mkdir -p ${path}
  #       echo "${patterns}" > ${path}/.stignore
  #     '';
  #   in
  #   {
  #     # Add ignore patters just for surface here:
  #     syncthingIgnorePatterns.text = ''
  #       # MinecraftPrismLauncherMainInstance
  #       ${ignorePattern "/home/yeshey/.local/share/PrismLauncher/instances/MainInstance/.minecraft" "
  #         // *
  #       "}
  #     '';
  #   };

  home = {
    # Specific packages # TODO check if you need these
    packages = with pkgs; [
      # texlive.combined.scheme-full
      github-desktop

      # osu-lazer
      gcc
    ];
  };
  home.persistence."/persistent" = lib.mkIf config.myHome.impermanence.enable {
    directories = [
      ".config/GitHub Desktop/"
    ];
  };
}
