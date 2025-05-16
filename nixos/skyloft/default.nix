{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

# To recover in case of loosing access through SSH do the following:
# Go to Oracle Cloud > Dashboard > Console Connection > Launch Cloud Shell Connection (You might have to delete the current connection and create a new one in "Create local connection" with you public key)
# Reboot the machine, and during boot select in the console a different generation

{
  imports = [
    ./hardware-configuration.nix
    #inputs.learnWithT.nixosModules.default
    # inputs.box64-binfmt.nixosModules.default
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
    plasma = {
      enable = false;
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

    copyFoldersOnedriver.jobs = {
      anarchyMineclone2ServerOnedriver = {
        repo = "/home/yeshey/PersonalFiles/Servers/luanti/anarchyMineclone2Borgbackup";
        paths = [ "/var/lib/luanti-anarchyMineclone2/world" ];
        user = "yeshey";  # This can be omitted if using mySystem.user default
        fuseRepoCheck = {
          timeout = "3m";
          interval = "15s";
          expectedFuseTypes = [ "onedrive" "fuse.onedrive" "rclone" ]; # This should include "fuse.onedriver" based on your mount output
          actualMountPointToCheck = "/home/yeshey/OneDriverISCTE"; # <<< SET THIS TO YOUR ACTUAL ONEDRIVE MOUNT POINT
        };
      };
    };

    borgFolderBackups.jobs = {
      anarchyMineclone2Server = {
        repo = "/home/yeshey/PersonalFiles/Servers/luanti/anarchyMineclone2Borgbackup";
        paths = [ "/var/lib/luanti-anarchyMineclone2/world" ];
        user = "yeshey";  # This can be omitted if using mySystem.user default
      };
      pixelmonMinecraftServer = {
        repo = "/home/yeshey/PersonalFiles/Servers/minecraft/pixelmonMinecraftBorgbackup";
        paths = [ "/srv/minecraft/pixelmon/world" ];
        user = "yeshey";  # This can be omitted if using mySystem.user default
      };
      zombies2MinecraftServer = {
        repo = "/home/yeshey/PersonalFiles/Servers/minecraft/zombies2MinecraftBorgbackup";
        paths = [ "/srv/minecraft/zombies2/world" ];
        user = "yeshey";  # This can be omitted if using mySystem.user default
      };
    };
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
    nextcloud = {
      enable = true;
      port = 85;
      hostName = "143.47.53.175:85"; # Or use "localhost" for local access
    };
    minecraft.enable = true;
    openvscodeServer.enable = true;
    nginxServer = {
      enable = true;
      port = 7843;
      listenAddress = "0.0.0.0";
    };
    luanti.enable = true;
    kubo.enable = true;
    mindustry-server.enable = false;
    searx.enable = true;
    ollama = {
      enable = true; 
      # acceleration = "cuda"; #or 'rocm' # this issue https://github.com/NixOS/nixpkgs/issues/321920
    };
    overleaf.enable = true;
  };

  # nix = {
  #   settings = {
  #     cores = 2; # settings this per machine
  #     max-jobs = 2;
  #   };
  # };

  programs.zsh = {
    shellAliases = {
    };
  };

  # box64-binfmt.enable = true;

  environment.systemPackages = [ 
    pkgs.file
#    pkgs.x86.steamcmd
#    pkgs.x86.katawa-shoujo
#    pkgs.x86.cmatrix
    pkgs.mangohud
#    pkgs.x86.xonotic
#    pkgs.x86.heroic
#    pkgs.x86.superTuxKart
#    pkgs.x86.glmark2
#    pkgs.x86.vulkan-toolsmjn
#    pkgs.x86.glxinfo 
  ];

#  boot.binfmt.emulatedSystems = ["i686-linux" "x86_64-linux"];

  nix = {
    distributedBuilds = true;
    buildMachines = [{
      hostName = "hyrulecastle";
      system = "x86_64-linux";
      sshUser = "yeshey";
      # Replace with the path to your SSH private key or use SSH agent
      sshKey = "/home/yeshey/.ssh/my_identity";
      supportedFeatures = [ # saw with nix show-config --json | jq -r '.["system-features"].value'
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
        ];
    }];
  };

  time.timeZone = "Europe/Madrid";

  system.autoUpgrade.allowReboot = true;

  networking.firewall.allowedTCPPorts = [
    8891 # for jupyternotebook servers (on this port) (`jupyter notebook --ip=0.0.0.0 --port=8891 --no-browser`)
  ];

  nixpkgs.config = {
    allowUnsupportedSystem = true;
    allowBroken = true;
    # permittedInsecurePackages # cant be in multiple files. Set it in mySystem
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "22.05";
}
