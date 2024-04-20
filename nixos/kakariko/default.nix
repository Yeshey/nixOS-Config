{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

let 
    # user = "yeshey";
    dataStoragePath = "/mnt/ntfsMicroSD-DataDisk";

    # TODO find a better way? see if its still needed
    # Wrapper to run steam with env variable GDK_SCALE=2 to scale correctly
    # nixOS wiki on wrappers: https://nixos.wiki/wiki/Nix_Cookbook#Wrapping_packages
    # Reddit: https://www.reddit.com/r/NixOS/comments/qha9t5/comment/hid3w3z/
    steam-scalled = pkgs.runCommand "steam" {
      buildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir $out
      # Link every top-level folder from pkgs.steam to our new target
      ln -s ${pkgs.steam}/* $out
      # Except the bin folder
      rm $out/bin
      mkdir $out/bin
      # We create the bin folder ourselves and link every binary in it
      ln -s ${pkgs.steam}/bin/* $out/bin
      # Except the steam binary
      rm $out/bin/steam
      # Because we create this ourself, by creating a wrapper
      makeWrapper ${pkgs.steam}/bin/steam $out/bin/steam \
        --set GDK_SCALE 2 \
        --add-flags "-t"
    '';

    stremio-scalled = pkgs.runCommand "stremio" {
      buildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir $out
      # Link every top-level folder from pkgs.stremio to our new target
      ln -s ${pkgs.stremio}/* $out
      # Except the bin folder
      rm $out/bin
      mkdir $out/bin
      # We create the bin folder ourselves and link every binary in it
      ln -s ${pkgs.stremio}/bin/* $out/bin
      # Except the stremio binary
      rm $out/bin/stremio
      # Because we create this ourself, by creating a wrapper
      makeWrapper ${pkgs.stremio}/bin/stremio $out/bin/stremio \
        --set QT_AUTO_SCREEN_SCALE_FACTOR 1 \
        --add-flags "-t"
    '';
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
    ./hardware-configuration.nix

    # (import ./configFiles/VM/VM.nix) # TODO
    # (import ./configFiles/dontStarveTogetherServer.nix) # TODO
    # (import ./configFiles/kubo.nix) # for ipfs # TODO
    # (import ./../oracleArmVM/configFiles/ngix-server.nix) # TODO ???
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

  mySystem = {
    plasma.enable = false;
    gnome.enable = true; # TODO activate both plasma and gnome same time, maybe expose display manager
    browser.enable = true;
    cliTools.enable = true;
    zsh.enable = true;
    gaming.enable = true;
    vmHost = true;
    dockerHost = true; 
    host = "kakariko";
    user = "yeshey"; # TODO make this into an option where you can do user."yeshey".home-manager.enable ) true etc.
    home-manager = {
      enable = true;
      home = ./home.nix;
    };
    hardware = {
      enable = true;
      bluetooth.enable = true;
      printers.enable = true;
      sound.enable = true;
      thermald = {
        enable = true;
        thermalConf = ./thermal-conf.xml;
      };
      nvidia.enable = false;
    };
    autoUpgrades.enable = true;    
    flatpaks.enable = true;
    i2p.enable = true;
    syncthing = {
      enable = true;
      dataStoragePath = "/mnt/ntfsMicroSD-DataDisk";
    };
    
    androidDevelopment.enable = false;
  };

  # swap in ext4:
  swapDevices = [ 
    {
      device = "/swapfile";
      priority = 0; # Higher numbers indicate higher priority.
      size = 10*1024;
      options = [ "nofail"];
    }
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  #powerManagement = { # TODO ???
  #  cpuFreqGovernor = "ondemand";
  #  cpufreq.min = 800000;
  #  cpufreq.max = 4700000;
  #};

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    stremio-scalled
    # Games
    steam-scalled
  ];

  #networking = { # TODO can you remove
  #  hostName = "kakariko"; # TODO make into variable
  #};

  system.stateVersion = "22.05";
}
