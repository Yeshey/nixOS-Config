{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

# To recover in case of loosing access through SSH do the following:
# Go to Oracle Cloud > Dashboard > Console Connection > Launch Cloud Shell Connection (You might have to delete the cuirrent connection and create a new one in "Create local connection" with you public key)
# Reboot the machine, and during boot select in the console a different generation

{
  imports = [
    ./hardware-configuration.nix
    ./backups.nix
    ./box86.nix
  ];

  nixpkgs = {
    # You can add overlays here
    config.allowBroken = true;
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

  # set an alias to poweroff ask if you're sure

  mySystem = rec {
    enable = true;
    plasma = {
      enable = true;
      defaultSession = "plasmax11";
    };
    gnome.enable = false; # TODO activate both plasma and gnome same time, maybe expose display manager
    ssh.enable = true;
    browser.enable = true;
    cliTools.enable = true;
    zsh.enable = true;
    gaming.enable = false;
    vmHost = true;
    dockerHost = true;
    host = "skyloft";
    user = "yeshey"; # TODO make this into an option where you can do user."yeshey".home-manager.enable ) true etc.
    home-manager = {
      enable = true;
      home = ./home.nix;
    };
    hardware = {
      enable = true;
      bluetooth.enable = false;
      printers.enable = false;
      sound.enable = true;
      thermald = {
        enable = false;
      };
      #nvidia.enable = false;
    };
    autoUpgrades = {
      enable = true;
      location = "github:Yeshey/nixOS-Config"; # "github:Yeshey/nixOS-Config"
      host = "skyloft";
      dates = "weekly";
    };
    flatpaks.enable = false;
    i2p.enable = false;
    syncthing = {
      enable = true;
      dataStoragePath = "/home/${user}";
    };
    androidDevelopment.enable = false;
    agenix = {
      enable = true;
      sshKeys.enable = true;
    };

    box86.enable = true;
  };

  toHost = {
    remoteWorkstation = {
      sunshine.enable = true;
      xrdp.enable = true;
    };
    dontStarveTogetherServer = {
      enable = false;
      path = "/home/yeshey/PersonalFiles/Servers/dontstarvetogether/SurvivalServerMadeiraSummer2/DoNotStarveTogetherServer";
    };
    nextcloud.enable = true;
    minecraft.enable = false;
    openvscodeServer.enable = true;
    ngixServer.enable = true;
    mineclone.enable = true;
    kubo.enable = true;
    mindustry-server.enable = true;
  };

  time.timeZone = "Europe/Madrid";

  system.autoUpgrade.allowReboot = false;

  nixpkgs.config = {
    allowUnsupportedSystem = true;
    #    allowUnfree = true;
    #permittedInsecurePackages = [ # for package openvscode-server
    #  "nodejs-16.20.2"
    #];
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "22.05";
}
