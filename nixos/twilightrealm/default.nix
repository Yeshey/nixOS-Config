{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

let
in
{
  imports = [
    ./hardware-configuration.nix
    # inputs.learnWithT.nixosModules.default
  ];

  mySystem = rec {
    enable = true;
    host = "twilightrealm";
    user = "yeshey"; # TODO make this into an option where you can do user."yeshey".home-manager.enable ) true etc.
    dataStoragePath = "/home/${user}";
    home-manager = {
      enable = true;
      home = ./home.nix;
    };
    plasma.enable = false;
    gnome = {
      enable = true; # TODO activate both plasma and gnome same time, maybe expose display manager
    };
    hyprland.enable = false;
    ssh = {
      enable = true;
    };
    browser.enable = true;
    cliTools.enable = true;
    zsh.enable = true;
    gaming.enable = false;
    vmHost = false;
    dockerHost = false;
    hardware = {
      enable = true;
      bluetooth.enable = true;
      printers.enable = false;
      sound.enable = true;
      thermald = {
        enable = false;
        thermalConf = ./thermal-conf.xml;
      };
      nvidia.enable = false;
    };
    autoUpgrades = {
      enable = false;
      location = "/home/yeshey/.setup";
      host = "kakariko";
      dates = "weekly";
    };
    flatpaks.enable = true;
    i2p.enable = false;
    syncthing = {
      enable = false;
    };

    androidDevelopment.enable = false;

    #agenix = {
    #  enable = false;
    #  sshKeys.enable = false;
    #};
    #isolateVMsNixStore = true;
    waydroid.enable = false;
    impermanence.enable = false;

    speedtest-tracker = {
      enable = false;
      # scheduele = "*/10 * * * *"; # Runs every 10 minutes, default is every hour
    };

    piperTextToSpeech.enable = false;
    snap.enable = false;
    autossh = {
     enable = false;
     remoteIP = "143.47.53.175";
     remoteUser = "yeshey";
     port = 2233;
    };
    nh.enable = true;
    wireguardClient.enable = false;
  };

  toHost = {
    #remoteWorkstation = {
    #  sunshine.enable = false;
    #  xrdp.enable = false;
    #};
    #dontStarveTogetherServer.enable = false;
    #nextcloud.enable = true;
    #minecraft.enable = false;
    # openvscodeServer = {
    #   enable = false;
    #   desktopItem = {
    #     enable = true;
    #     remote = "oracle";
    #   };
    # };
    #nginxServer.enable = true;
    #mineclone.enable = true;
    #kubo.enable = true;
    #freeGames.enable = false;

    ollama.enable = false; 
    searx.enable = false;
  };

  nix = {
    settings = {
      cores = 4; # settings this per machine
      max-jobs = 2;
    };
  };

  environment.systemPackages = with pkgs; [
    # jetbrains-toolbox
    # Games
    # steam-scalled
  ];

  swapDevices =
    [ 
      {
        device = "/swapfile";
        size = 8*1024;
        priority = 0; # Higher numbers indicate higher priority.
      }
    ];

  # Bootloader.
  boot.loader.systemd-boot = {
   enable = true;
   configurationLimit = 10; # You can leave it null for no limit, but it is not recommended, as it can fill your boot partition.
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  system.stateVersion = "22.05";
}
