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
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
    ./pci-passthrough.nix
    ./vgpu.nix
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
    enable = true; # if false, disables all below config, (TODO if true, sets my minimal server config & imports hm)
    # all the options
    host = "hyrulecastle";
    user = "yeshey";
    dataStoragePath = "/mnt/DataDisk";
    plasma.enable = true;
    gnome.enable = false; # TODO activate both plasma and gnome same time, maybe expose display manager
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
    autoUpgrades = {
      enable = false;
      location = "/home/yeshey/.setup";
      host = "hyrulecastle";
      dates = "daily";
    };
    autoUpgradesOnShutdown = {
      enable = true;
      gitRepo = "git@github.com:Yeshey/nixOS-Config.git";
      ssh_key = "/home/yeshey/.ssh/my_identity";
      host = "hyrulecastle";
      dates = "*-*-1/3"; # "Fri *-*-* 20:00:00"; # Every Friday at 19:00 "*:0/5"; # Every 5 minutes
    };
    flatpaks.enable = true;
    i2p.enable = true;

    borgBackups = {
      enable = true;
      paths = [
        "/mnt/DataDisk/PersonalFiles"
        "/home/${user}"
      ];
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
    };

    # todo add samba support properly, rn its being added just to the laptop if vgpu is enabled
    # samba = {...}

    androidDevelopment.enable = false;

    agenix = {
      enable = true;
      sshKeys.enable = true;
    };

    waydroid.enable = true;
    #isolateVMsNixStore = true;
    impermanence.enable = false;

    speedtest-tracker.enable = true;
  };

  toHost = {
    remoteWorkstation = {
      sunshine.enable = false;
      xrdp.enable = false;
    };
    dontStarveTogetherServer.enable = false;
    #nextcloud.enable = true;
    #minecraft.enable = false;
    #openvscodeServer.enable = true;
    #ngixServer.enable = true;
    #mineclone.enable = true;
    kubo.enable = true;
    freeGames.enable = false;
  };

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

  nixpkgs.config = {
    # allowUnsupportedSystem = true;
    #    allowUnfree = true;
    # TODO remove this below 
    #permittedInsecurePackages = [ # for package openvscode-server
    #  "nodejs-16.20.2"
    #];
  };

  # nix.package = lib.mkForce pkgs.nixVersions.latest; # needed for clean to work without illigal character error?

  # roblox with sober (to not get the VK_ERROR_DEVICE_LOST error)
  #nixpkgs.config.nvidia.acceptLicense = true;
  #hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;

  virtualisation.docker.storageDriver = "btrfs"; # for docker

  # hardware accelaration
  hardware.opengl = {
    enable = true;
    extraPackages = [
      pkgs.vaapiVdpau
      pkgs.libvdpau-va-gl
    ];
  };

  # onedrive --reauth
  # systemctl restart --user onedrive@onedrive.service
  # journalctl --user -f -u onedrive@onedrive.service
  services.onedrive.enable = true;

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
