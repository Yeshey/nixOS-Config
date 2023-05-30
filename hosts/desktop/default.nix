#
#  Specific system configuration settings for desktop
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ ./desktop
#   │        ├─ default.nix *
#   │        └─ hardware-configuration.nix
#   └─ ./modules
#       └─ ./desktop
#           └─ ./qemu
#               └─ default.nix
#

{ config, pkgs, user, location, dataStoragePath, lib, ... }:

{
imports = [
  (import ./hardware-configuration.nix)
  (import ./nixFiles/pci-passthrough.nix)
  (import (builtins.fetchurl{
        url = "https://github.com/NixOS/nixpkgs/raw/63c34abfb33b8c579631df6b5ca00c0430a395df/nixos/modules/programs/looking-glass.nix";
        sha256 = "sha256:1lfrqix8kxfawnlrirq059w1hk3kcfq4p8g6kal3kbsczw90rhki";
      } ))  #(import ./nixFiles/looking-glass.nix)
];

  # Following this github guide: https://github.com/tuh8888/libvirt_win10_vm

  # For GPU passthrough to the VM, but instead I'm going to try to use GPU virtualisation through the discovered jailbreak: https://github.com/DualCoder/vgpu_unlock
  # https://gist.github.com/WhittlesJr/a6de35b995e8c14b9093c55ba41b697c
  pciPassthrough = {
    # you will also need to set hardware.nvidia.prime.offload.enable = true for this GPU passthrough to work  (or the sync method?)
    enable = true;
    pciIDs = "";
    #pciIDs = "10de:1f11,10de:10f9,8086:1901,10de:1ada" ; # Nvidia VGA, Nvidia Audia,... "10de:1f11,10de:10f9,8086:1901,10de:1ada";
    libvirtUsers = [ "${user}" ];
  };

  programs.looking-glass = let
    # Looking glass B6 version in nix: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/virtualization/looking-glass-client/default.nix
    myPkgs = import (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/9fa5c1f0a85f83dfa928528a33a28f063ae3858d.tar.gz";
    }) {};

    LookingGlassB6 = myPkgs.looking-glass-client;
  in {
    enable = true;
    package = LookingGlassB6;
  };

  #boot.kernelPackages = pkgs.linuxPackages_5_10; # needed for this linuxPackages_5_19
  hardware.nvidia = {
    vgpu = {
      enable = true; # Install NVIDIA KVM vGPU + GRID driver
      unlock.enable = true; # Unlock vGPU functionality on consumer cards using DualCoder/vgpu_unlock project.
      fastapi-dls = {
        enable = true;
        local_ipv4 = "192.168.1.109";
        timezone = "Europe/Lisbon";
        #docker-directory = /mnt/dockers;
      };
    };
  };
  
  # Manage Temperature, prevent throttling
  # https://github.com/linux-surface/linux-surface/issues/221
  # laptop thermald with: https://github.com/intel/thermal_daemon/issues/42#issuecomment-294567400
  services.power-profiles-daemon.enable = true;
  services.thermald = {
    debug = false;
    enable = true;
    configFile = ./configFiles/thermal-conf.xml; #(https://github.com/linux-surface/linux-surface/blob/master/contrib/thermald/thermal-conf.xml)
  };
  systemd.services.thermald.serviceConfig.ExecStart = let # running with --adaptive ignores the config file. Issue raised: https://github.com/NixOS/nixpkgs/issues/201402
    cfg = config.services.thermald;
  in lib.mkForce ''
          ${cfg.package}/sbin/thermald \
            --no-daemon \
            --config-file ${location}/hosts/desktop/configFiles/thermal-conf.xml \
        '';

  #services.thermald = {
  #  debug = false;
  #  enable = true;
  #};

  # systemctl status borgbackup-job-rootBackup.service/timer
  services.borgbackup.jobs = { # for a local backup
    rootBackup = {
      # Use `sudo borg list -v /mnt/hdd-btrfs/Backups/borgbackup` to check the archives created
      # Use `sudo borg info /mnt/hdd-btrfs/Backups/borgbackup::<NameOfArchive>` to see details
      # Use `sudo borg extract /mnt/hdd-btrfs/Backups/borgbackup::<NameOfArchive>` to extract the specified archive to the current directory
      paths = [ "${dataStoragePath}/PersonalFiles" "/home/${user}"]; 
      exclude = [ 
          # Largest cache dirs
          ".cache"
          "*/cache2" # firefox
          "*/Cache"
          ".config/Slack/logs"
          ".config/Code/CachedData"
          ".container-diff"
          ".npm/_cacache"
          # Work related dirs
          "*/node_modules"
          "*/bower_components"
          "*/_build"
          "*/.tox"
          "*/venv"
          "*/.venv"
          # Personal Home Dirs
          "*cache*"
          "*/Android"
          "*/.gradle"
          "*/.var"
          "*/.cabal"
          "*/.vscode"
          "*/.stremio-server"
          "*/grapejuice"
          "*/baloo"
          "*/share/containers"
          "*/lutris"
          "*/Steam"
          "*/.config"
          "*/Trash"
          "*/Games"

          # Personal Dirs
          "*/RecordedClasses"

       ];
      repo = "/mnt/hdd-btrfs/Backups/borgbackup";
      encryption = {
        mode = "none";
      };
      prune.keep = {
        within = "1d"; # Keep all archives from the last day
        daily = 2; # keep the latest backup on each day, up to 7 most recent days with backups (days without backups do not count)
        weekly = 2; 
        monthly = 2;
        yearly = 5;
      };
      extraCreateArgs = "--stats";
      #encryption = {
      #  mode = "repokey";
      #  passphrase = "secret";
      #};
      compression = "auto,lzma";
      startAt = "weekly"; # weekly # *:0/9 every 9 minutes # daily
    };
  };

  networking.hostName = "nixOS-Laptop"; # Define your hostname.
  # hardware.enableAllFirmware = true; #?

#     ___            __ 
#    / _ )___  ___  / /_
#   / _  / _ \/ _ \/ __/
#  /____/\___/\___/\__/      

  boot.loader = {

    timeout = 2;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      version = 2;
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

  # Docker 
  # Docker to automatically grab Epic Games Free games
  # Follow the service log with `journalctl -fu podman-epic_games.service`
  # You have to put the config.json5 file in /mnt/Epic_Games_Claimer/config.json5

  /*
  # My epic games accounts are not very well trusted anymore...
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true; # Big WTF
  # Help from https://github.com/NixOS/nixpkgs/issues/68349 and https://docs.docker.com/storage/storagedriver/btrfs-driver/
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.oci-containers.containers = {
    epic_games = {
      image = "charlocharlie/epicgames-freegames:latest";
      volumes = [ "/mnt/Epic_Games_Claimer:/usr/app/config:rw" ];
      ports = [ "3000:3000" ];
      # extraOptions = [ "-p 3000:3000"];
      # autoStart = true;
    };
  };
  */

  # KDE Plasma
  services.xserver = {
    enable = true; # Enable the X11 windowing system.
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "yeshey";
      sddm = {
        enable = true;
      };
      defaultSession = "plasma"; # "none+bspwm" or "plasma"
    };
    desktopManager.plasma5 = {
      enable = true;
      # supportDDC = true; # doesnt work with nvidia # to support changing brightness for external monitors (https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800)
    };
    # windowManager.bspwm.enable = true; # but doesn't work
  };


  # tmp solution for audio not working
  # force VM to use pulseaudio, it seems to be necessary
  # What is mkForce and mkDefault and mkOverride: https://discourse.nixos.org/t/what-does-mkdefault-do-exactly/9028 
  #services.pipewire.enable = lib.mkForce false; # same as mkoverride 50 - the option has a priority of 50
  #hardware.pulseaudio.enable = lib.mkForce true;
  #hardware.pulseaudio.support32Bit = true;    ## If compatibility with 32-bit applications is desired.
  #nixpkgs.config.pulseaudio = true;
  #hardware.pulseaudio.extraConfig = "load-module module-combine-sink";
  # Scream Audio Server Service

  /*
  systemd.user.services.scream = {
    enable = true;
    description = "Scream Audio Server";
    serviceConfig = {
        ExecStart = "${pkgs.scream}/bin/scream -v -o pulse -i virbr0 -p 4010";
        Restart = "always";
    };
    wantedBy = [ "default.target" ];
    requires = [ "pipewire-pulse.service" ];
  };  
  */

  # OVERLAYS
  nixpkgs.overlays = [                          # This overlay will pull the latest version of Discord (but I guess it doesnt work)
  
  /*
    (self: super: {
      looking-glass-client = super.looking-glass-client.overrideAttrs (
        old: { 
          #pname = "looking-glass-client";
          #version = "B6";

          src = pkgs.fetchFromGitHub {
            owner = "gnif";
            repo = "LookingGlass";
            rev = "B6-rc1";
            sha256 = "sha256-6vYbNmNJBCoU23nVculac24tHqH7F4AZVftIjL93WJU=";
            fetchSubmodules = true;
          };
          
          buildInputs = old.buildInputs ++ [
            pkgs.pipewire
            pkgs.pulseaudio
            pkgs.libsamplerate
          ];

        }
      );
    })
    */

  ];

  environment.systemPackages = [

    # Epic_Games_Claimer
    # docker

    # tmp
    # virtualbox
    # texlive.combined.scheme-full # LaTeX
    #LookingGlassB6
    pkgs.scream

    # Games
    pkgs.steam
    pkgs.grapejuice # roblox

    # FOR PLASMA DESKTOP
    pkgs.scrot # for plasma config saver widget
    pkgs.kdialog # for plasma config saver widget
    pkgs.ark # Compress and Uncompress files
    pkgs.sddm-kcm # for sddm configuration in settings
    pkgs.kate # KDEs notepad    
  ];

  # Syncthing, there's no easy way to add ignore patters, so we're doing it like this for now:
  # But it looks like there also isn't an easy way to add them like we can in home manager with file.source...

}
