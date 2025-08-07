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
  imports =
    [
      ./hardware-configuration.nix
      "${builtins.fetchTarball {
        url = "https://github.com/nix-community/disko/archive/v1.11.0.tar.gz";
        sha256 = "sha256:13brimg7z7k9y36n4jc1pssqyw94nd8qvgfjv53z66lv4xkhin92";
      }}/module.nix"

     ./disk-config.nix
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
    #agenix = {
    #  enable = false;
    #  sshKeys.enable = false;
    #};

    # to use this you need to create a remote with the name onedriveISCTE with `rclone config`
    # with restic-browser you would check the contents of the backup by putting onedriveISCTE:ResticBackups/servers in remote section and selecting type rclone
    # pass é aquela que das set na config aqui
    resticRcloneBackups.jobs = {
      #check this backup with journalctl -fu restic-backups-servers.service
      servers = {
        enable = true;
        user = "root"; # To access /mnt/DataDisk and /home/yeshey
        paths = [
          "/var/lib/luanti-anarchyMineclone2/world" # chown -R luanti-anarchyMineclone2:luanti /var/lib/luanti-anarchyMineclone2
          "/srv/minecraft/mainServer/world" # chown -R minecraft:minecraft /srv/minecraft/mainServer
          "/opt/docker/overleaf/overleaf-data" # chown -R root:root /opt/docker/overleaf/overleaf-data
        ];
        rcloneRemoteName = "onedriveISCTE";
        rcloneRemotePath = "ResticBackups/servers"; # This is like your 'repo' path, but on the remote
        #rcloneConfigFile = "/var/lib/secrets/rclone/school-onedrive.conf";
        #passwordFile = "/var/lib/secrets/restic/school-onedrive-password";
        rcloneConfigFile = "/home/${user}/.config/rclone/rclone.conf";
        passwordFile = "${builtins.toFile "restic-password" "123456789"}";
        initialize = true; # Good for the first run

        startAt = "*-*-* 14:00:00"; # Sets the default to 2 PM daily
        randomizedDelaySec = "6h"; # Spread runs

        prune.enable = true; # Enable automatic pruning
        prune.keep = {
          within = "1d";
          daily = 2;
          weekly = 2;
          monthly = 6;
          yearly = 3;
        };

        exclude = [
          "**/.var"
          "**/RecordedClasses"
          "**/Games"
          # Add more cache/temporary directories
        ];

        noCache = false; # Use Restic cache (recommended)
        extraBackupArgs = [ "--verbose=1" ];
        # extraRcloneOpts = [ "onedrive-chunk-size=250M" ]; # If you find OneDrive needs larger chunks for Restic
      };
    };
    nh.enable = true;
    impermanence.enable = true;
  };

  toHost = {
    remoteWorkstation = {
      sunshine.enable = false;
      xrdp.enable = true;
    };
    dontStarveTogetherServer = {
      enable = false;
      path = "/home/yeshey/PersonalFiles/Servers/dontstarvetogether/SurvivalServerMadeiraSummer2/DoNotStarveTogetherServer";
    };
    nextcloud = {
      enable = false;
      port = 85;
      hostName = "143.47.53.175:85"; # Or use "localhost" for local access
    };
    minecraft.enable = true;
    openvscodeServer.enable = false;
    code-server.enable = true;
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
    wireguardServer.enable = true;
  };

  swapDevices = [
    { device = "/swap/swapfile"; size = 4*1024; 
      priority = 0; # Higher numbers indicate higher priority.
    }
  ];

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

  # you should also add `qdbus org.kde.LogoutPrompt /LogoutPrompt  org.kde.LogoutPrompt.promptLogout` to the command to run when inactive for a certain time in KDE plasma
  # Also screen locking, and screen locking after waking f rom sleep, should be disabled
  # headless server doesn't need sddm (xrdp doesn't need it either)
  services.displayManager.sddm = {
    enable = false;
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

  # hardening options
  services.openssh = {
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.05";
}
