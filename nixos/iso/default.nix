# build me with `nix build ~/.setup#nixosConfigurations.iso.config.system.build.isoImage`

{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ 
    # ./hardware-configuration.nix 
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma5.nix")
  ];

  nixpkgs = {
    # You can add overlays here
    hostPlatform = "x86_64-linux";
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
    host = "live";
    user = "yeshey";
    dataStoragePath = "~/Documents";
    gnome.enable = false;
    plasma.enable = true;
    ssh = {
      enable = true;
    };
    browser.enable = true;
    cliTools.enable = true;
    zsh.enable = true;
    home-manager = {
      enable = true;
      home = ./home.nix;
      #dataStoragePath = dataStoragePath;
    };
    hardware = {
      enable = true;
      bluetooth.enable = true;
      thermald.enable = true;
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
  };

  boot.loader.timeout = lib.mkForce 10;

  networking.hostName = "yeshey-nixos-live";

  # Guest VM options
  services.spice-vdagentd.enable = true;
  services.spice-autorandr.enable = true; # auto resize guest
  services.spice-webdavd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  #environment.systemPackages = with pkgs; [ 
  #  calamares-nixos
  #  calamares-nixos-extensions 
  #];
}
