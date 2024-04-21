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
  dataStoragePath = "/mnt/DataDisk";
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
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

  mySystem = rec {
    # all the options
    plasma.enable = true;
    gnome.enable = false; # TODO activate both plasma and gnome same time, maybe expose display manager
    browser.enable = true;
    cliTools.enable = true;
    zsh.enable = true;
    gaming.enable = true;
    vmHost = true;
    dockerHost = true; 
    host = "hyrulecastle";
    user = "yeshey";
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
      nvidia = {
        enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    autoUpgrades.enable = true;    
    flatpaks.enable = true;
    i2p.enable = true;

    borgBackups = {
      enable = true;
      paths = [ "/mnt/DataDisk/PersonalFiles" "/home/${user}" ];
      repo = "/mnt/hdd-btrfs/Backups/borgbackup";
      startAt = "daily";
      prune.keep = {
          within = "1d"; # Keep all archives from the last day
          daily = 2; # keep the latest backup on each day, up to 7 most recent days with backups (days without backups do not count)
          weekly = 2; 
          monthly = 6;
          yearly = 3;
        };
      exclude = [ "*/RecordedClasses" ];
    };
    syncthing = {
      enable = true;
      dataStoragePath = "/mnt/DataDisk";
    };
    
    androidDevelopment.enable = false;
  };

  virtualisation.docker.storageDriver = "btrfs"; # for docker

  # hardware accelaration
  hardware.opengl = {
    enable = true;
    extraPackages = [
      pkgs.vaapiVdpau
      pkgs.libvdpau-va-gl
    ];
  };

  #programs.zsh.enable = true;
  #users.users.yeshey.shell = pkgs.zsh;

  boot.loader = {
    timeout = 2;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      device = "nodev";
      useOSProber = true;
      # default = "saved"; # doesn't work with btrfs :(
      extraEntries = ''
        menuentry "Reboot" {
            reboot
        }
        menuentry "Shut Down" {
            halt
        }
        # Option info from /boot/grub/grub.cfg, technotes "Grub" section for more details
        menuentry "NixOS - Console" --class nixos --unrestricted {
        search --set=drive1 --fs-uuid 69e9ba80-fb1f-4c2d-981d-d44e59ff9e21
        search --set=drive2 --fs-uuid 69e9ba80-fb1f-4c2d-981d-d44e59ff9e21
          linux ($drive2)/@/nix/store/ll70jpkp1wgh6qdp3spxl684m0rj9ws4-linux-5.15.68/bzImage init=/nix/store/c2mg9sck85ydls81xrn8phh3i1rn8bph-nixos-system-nixos-22.11pre410602.ae1dc133ea5/init loglevel=4 3
          initrd ($drive2)/@/nix/store/s38fgk7axcjryrp5abkvzqmyhc3m4pd1-initrd-linux-5.15.68/initrd
        }
      '';
    };
  };

  #powerManagement = { # TODO ???
  #  cpuFreqGovernor = "ondemand";
  #  cpufreq.min = 800000;
  #  cpufreq.max = 4700000;
  #};

  #networking = { # TODO can you remove?
  #  hostName = "nixos-${inputs.host}"; # TODO make into variable
  #};

  system.stateVersion = "22.05";
}
