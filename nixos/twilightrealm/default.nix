{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [ 
    ./hardware-configuration.nix 
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
  };

  mySystem = rec {
    enable = true;
    # all the options
    host = "twilightrealm";
    user = "yeshey";
    dataStoragePath = "~/Documents";
    plasma.enable = true;
    gnome.enable = false; # TODO activate both plasma and gnome same time, maybe expose display manager
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
    home-manager = {
      enable = true;
      home = ./home.nix;
      #dataStoragePath = dataStoragePath;
    };
    hardware = {
      enable = true;
      bluetooth.enable = true;
      printers.enable = false;
      sound.enable = true;
      nvidia = {
        enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      lvm.enable = false;
    };
    autoUpgrades = {
      enable = false;
      location = "/home/yeshey/.setup";
      host = "hyrulecastle";
      dates = "daily";
    };
    flatpaks.enable = false;
    i2p.enable = false;

    hardware.thermald = {
      #enable = false;
      #thermalConf = ./../kakariko/thermal-conf.xml;
    };

    #agenix = {
    #  enable = false;
    #  sshKeys.enable = false;
    #};
  };

  swapDevices =
    [ 
      { device = "/var/swapfile"; 
        size = 6*1024; 
        priority = 0; # Higher numbers indicate higher priority.
        options = [ "nofail" ];
      }
    ];

  # Guest VM options
  services.spice-vdagentd.enable = true;
  services.spice-autorandr.enable = true; # auto resize guest
  services.spice-webdavd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  environment.systemPackages = with pkgs; [
    # Games
    steam
  ];

  system.stateVersion = "22.05";
}
