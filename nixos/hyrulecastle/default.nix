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

  hdaJackRetaskFwContent = ''
    [codec]
    0x10ec0257 0x17aa3810 0

    [pincfg]
    0x12 0x90a60120
    0x13 0x40000000
    0x14 0x90170110
    0x18 0x411111f0
    0x19 0x90a60160
    0x1a 0x411111f0
    0x1b 0x411111f0
    0x1d 0x40661b45
    0x1e 0x411111f0
    0x21 0x0421101f
  '';

  # Create a derivation that produces a directory containing the firmware file
  hdaJackRetaskFwPkg = pkgs.runCommand "hda-jack-retask-custom-fw" {
    # buildInputs can be empty if no tools are needed beyond shell builtins
  } ''
    # Create the standard directory structure for firmware
    mkdir -p $out/lib/firmware 
    # Write the content to the firmware file within that structure
    echo "${hdaJackRetaskFwContent}" > $out/lib/firmware/hda-jack-retask.fw
  '';
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
    ./pci-passthrough.nix
    ./vgpu/vgpu.nix
    # inputs.learnWithT.nixosModules.default
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

      # tmp so firefox doesn't take the whole year to build
      (self: super: {
        onnxruntime = super.onnxruntime.override {
          cudaSupport = false;
        };
      })

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
  };

  mySystem = rec {
    enable = true; # if false, disables all below config, (TODO if true, sets my minimal server config & imports hm)
    # all the options
    host = "hyrulecastle";
    user = "yeshey";
    guest.enable = true;
    dataStoragePath = "/home/${user}";
    plasma.enable = false;
    gnome.enable = true; # TODO activate both plasma and gnome same time, maybe expose display manager
    cosmic.enable = false;
    hyprland.enable = false;
    ssh = {
      enable = true;
    };
    browser.enable = true;
    cliTools.enable = true;
    zsh = {
      enable = true;
      falkeLocation = "/home/yeshey/.setup";
    };
    gaming.enable = true;
    vmHost = true;
    dockerHost = true;
    home-manager = {
      enable = true;
      home = ./home.nix;
      #dataStoragePath = dataStoragePath;
    };
    hardware = {
      enable = true; # TODO, if you set this to false, should disable everything
      nvidia = {
        enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
        GPUName = "GeForce RTX 2060 Mobile";
      };
      bluetooth.enable = true;
      printers.enable = true;
      sound.enable = true;
      thermald = {
        enable = true;
        thermalConf = ./thermal-conf.xml;
      };
      lvm.enable = false;
    };
    # autoUpgrades = {
    #   enable = false;
    #   location = "/home/yeshey/.setup";
    #   host = "hyrulecastle";
    #   dates = "daily";
    # };
    # autoUpgradesOnShutdown = {
    #   enable = false;
    #   gitRepo = "git@github.com:Yeshey/nixOS-Config.git";
    #   ssh_key = "/home/yeshey/.ssh/my_identity";
    #   host = "hyrulecastle";
    #   dates = "*-*-1/3"; # "Fri *-*-* 20:00:00"; # Every Friday at 19:00 "*:0/5"; # Every 5 minutes
    # };
    autoUpdatesOnShutdown = {
      enable = true;
      location = "github:Yeshey/nixOS-Config";
      host = "hyrulecastle";
    };
    flatpaks.enable = true;
    i2p.enable = false;

    # borgBackups = {
    #   enable = true;
    #   paths = [
    #     "/mnt/DataDisk/PersonalFiles"
    #     "/home/${user}"
    #   ];
    #   repo = "/mnt/hdd-btrfs/Backups/borgbackup";
    #   startAt = "daily";
    #   prune.keep = {
    #     within = "1d"; # Keep all archives from the last day
    #     daily = 2; # keep the latest backup on each day, up to 7 most recent days with backups (days without backups do not count)
    #     weekly = 2;
    #     monthly = 6;
    #     yearly = 3;
    #   };
    #   exclude = [ "*/RecordedClasses" ];
    # };

    syncthing = {
      enable = true;
    };

    # todo add samba support properly, rn its being added just to the laptop if vgpu is enabled
    # samba = {...}

    androidDevelopment.enable = true;

    #agenix = {
    #  enable = true;
    #  sshKeys.enable = true;
    #};

    waydroid.enable = true;
    #isolateVMsNixStore = true;
    impermanence.enable = false;

    speedtest-tracker = {
      enable = true;
      # scheduele = "*/10 * * * *"; # Runs every 10 minutes, default is every hour
    };

    snap.enable = true;
    autossh = {
     enable = true;
     remoteIP = "143.47.53.175";
     remoteUser = "yeshey";
     port = 2232;
    };
    aagl.enable = false;
    nh.enable = true;

    # to use this you need to create a remote with the name onedriveISCTE with `rclone config`
    # with restic-browser you would check the contents of the backup by putting onedriveISCTE:ResticBackups/mainBackupOneDrive in remote section and selecting type rclone
    # pass é aquela que das set na config aqui
    resticRcloneBackups.jobs = {
      #check this backup with journalctl -fu restic-backups-mainBackupOneDrive.service
      mainBackupOneDrive = {
        enable = true;
        user = "yeshey"; # To access /mnt/DataDisk and /home/yeshey
        paths = [
          # "/mnt/DataDisk/PersonalFiles"
          "/home/${user}" # Dynamically gets 'yeshey'
        ];
        rcloneRemoteName = "OneDriveISCTE";
        rcloneRemotePath = "ResticBackups/mainBackupOneDrive"; # This is like your 'repo' path, but on the remote
        #rcloneConfigFile = "/var/lib/secrets/rclone/school-onedrive.conf";
        #passwordFile = "/var/lib/secrets/restic/school-onedrive-password";
        # rcloneConfigFile = "";
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
    allTor.enable = false;
    globalprotect.enable = true;
    rcloneBisync.enable = true;
    virtualbox.enable = true;
  };

  toHost = {
    remoteWorkstation = {
      sunshine.enable = false;
      # xrdp = {
      #   enable = false;
      #   desktopItem = {
      #     enable = true;
      #     remote.ip = "143.47.53.175";
      #     remote.user = "yeshey";
      #     # extraclioptions = "/w:1920 /h:1080 /smart-sizing /kbd:0x0816 /audio-mode:1 /clipboard /network:modem /compression";
      #   };
      # };
    };
    dontStarveTogetherServer.enable = false;
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
    kubo.enable = false;
    freeGames.enable = false;
    searx.enable = false;
    ollama = {
      enable = false; 
      # acceleration = "cuda"; #or 'rocm' # this issue https://github.com/NixOS/nixpkgs/issues/321920
    };
    openhands.enable = false;
    overleaf.enable = false;
  };

  # learnWithT = {
  #   development.openPorts.enable = true;
  #   appwrite = {
  #     enable = false;
  #   };
  # };

  mySystemHyruleCastle = {
    # https://gist.github.com/WhittlesJr/a6de35b995e8c14b9093c55ba41b697c
    # Enable the module with pciIDs = ""; and then run one of these commands to find the pciIDs:
    # for d in /sys/kernel/iommu_groups/*/devices/*; do n="${d#*/iommu_groups/*}"; n="${n%%/*}"; printf 'IOMMU Group %s \t' "$n"; lspci -nns "${d##*/}"; done | sort -h -k 3 | grep --color -e ".*NVIDIA.*" -e "^"
    # nix-shell -p pciutils --command "sudo lspci -nnk" | grep --color -e ".*NVIDIA.*" -e "^"
    pciPassthrough = {
      # see https://youtu.be/KVDUs019IB8?t=795 (you need to add all 4 of the GPU PCI devices)
      # in depth guide? https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
      # you will also need to set hardware.nvidia.prime.offload.enable = true for this GPU passthrough to work  (or the sync method?)
      enable = false;
      pciIDs = "";
      #pciIDs = "10de:1f11,10de:10f9,8086:1901,10de:1ada"; # Nvidia VGA, Nvidia Audia,... ;
      #libvirtUsers = [ "yeshey" ];
    };
    vgpu.enable = false;
  };

  services.displayManager.gdm.autoSuspend = false;

  nix = {
    settings = {
      cores = 6; # settings this per machine
      max-jobs = 4;
    };
  };

  # on hyrule castle I want it so when I close the lid it doesn't suspend
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  # nix.package = lib.mkForce pkgs.nixVersions.latest; # needed for clean to work without illigal character error?

  # roblox with sober (to not get the VK_ERROR_DEVICE_LOST error)
  #nixpkgs.config.nvidia.acceptLicense = true;
  #hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;

  virtualisation.docker.storageDriver = "btrfs"; # for docker

  # hardware accelaration
  hardware.graphics = {
    enable = true;
    extraPackages = [
      pkgs.libva-vdpau-driver
      pkgs.libvdpau-va-gl
    ];
  };

  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];  

  hardware.nvidia-container-toolkit.enable = true;
  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  # onedrive --reauth
  # systemctl restart --user onedrive@onedrive.service
  # journalctl --user -f -u onedrive@onedrive.service
  # services.onedrive.enable = true;
  # services.onedrive.package = pkgs.unstable.onedrive;
  # systemd.user.services."onedrive@" = {
  #   # allow at most 3 restarts… within a 10‑minute window
  #   unitConfig = {
  #     StartLimitBurst = "5";
  #     StartLimitIntervalSec = "600s";
  #   };
  # };
  environment.systemPackages = with pkgs; [ 
    
  ];

  #programs.zsh.enable = true;
  #users.users.yeshey.shell = pkgs.zsh;

  # Trusted Platform Module:
  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;  # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
  security.tpm2.tctiEnvironment.enable = true;  # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables

/*
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10; # You can leave it null for no limit, but it is not recommended, as it can fill your boot partition.
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
*/

  boot.loader = {
    timeout = 2;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    systemd-boot = {
      enable = true;
      configurationLimit = 15; # You can leave it null for no limit, but it is not recommended, as it can fill your boot partition.
      memtest86.enable = true; # to see if there is corruption: https://discourse.nixos.org/t/an-easier-way-to-repair-corrupted-nix-db/35915/13?u=yeshey
    };
  };

  # Enable using internal Mic While headphones connected in jack
  # found out by launching `hdajackretask`, going to Raltek ALC257, set Black Mic Override to "Internal mic" 
  # Make the firmware file available to the kernel
  hardware.firmware = [ hdaJackRetaskFwPkg ];
  # Explicitly tell the snd-hda-intel kernel module to load this patch.
  boot.extraModprobeConfig = ''
    options snd-hda-intel patch=hda-jack-retask.fw
  '';

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
