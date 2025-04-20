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
    ./backups.nix
    #inputs.learnWithT.nixosModules.default
    inputs.box64-binfmt.nixosModules.default
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

  # set an alias to poweroff ask if you're sure

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
  };

  box64-binfmt.enable = true;

  environment.systemPackages = [ 
    pkgs.file
    pkgs.x86.steamcmd
    pkgs.x86.katawa-shoujo
    pkgs.x86.cmatrix
    pkgs.mangohud
    pkgs.x86.xonotic
    pkgs.x86.heroic
    pkgs.x86.superTuxKart
    pkgs.x86.glmark2
    pkgs.x86.vulkan-tools
    pkgs.x86.glxinfo 
  ];

    nix = {
      distributedBuilds = true;
      buildMachines = [{
        hostName = "hyrulecastle";
        system = "x86_64-linux";
        sshUser = "yeshey";
        # Replace with the path to your SSH private key or use SSH agent
        sshKey = "/home/yeshey/.ssh/my_identity";
        maxJobs = 1;
          supportedFeatures = [ # saw with nix show-config --json | jq -r '.["system-features"].value'
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
           ];
      }];
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
    minecraft.enable = true;
    openvscodeServer.enable = true;
    ngixServer.enable = true;
    mineclone.enable = false;
    mineclonia.enable = true;
    luanti.enable = true;
    kubo.enable = true;
    mindustry-server.enable = false;
    searx.enable = true;
    ollama = {
      enable = true; 
      # acceleration = "cuda"; #or 'rocm' # this issue https://github.com/NixOS/nixpkgs/issues/321920
    };
    # overleaf.enable = true; # fiasco
  };

  boot.binfmt.emulatedSystems = ["i686-linux" "x86_64-linux" "i386-linux" "i486-linux" "i586-linux" "i686-linux"];

  time.timeZone = "Europe/Madrid";

  system.autoUpgrade.allowReboot = true;

  networking.firewall.allowedTCPPorts = [
    8891 # for jupyternotebook servers (on this port) (`jupyter notebook --ip=0.0.0.0 --port=8891 --no-browser`)
  ];

  nixpkgs.config = {
    allowUnsupportedSystem = true;
    allowBroken = true;
    #    allowUnfree = true;
    permittedInsecurePackages = [
      #"python3.12-chromadb-0.5.20" # ollama
    ];
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "22.05";
}
