# initialy generated with nixos-generate-config
{
  inputs,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [ "i915.force_probe=46a6" ]; # "i915.force_probe=46a6"

  # fileSystems."/" = {
  #   device = lib.mkDefault "/dev/disk/by-uuid/69e9ba80-fb1f-4c2d-981d-d44e59ff9e21";
  #   fsType = "btrfs";
  #   options = [
  #     "subvol=@"
  #     "defaults"
  #     "x-gvfs-show" # show in gnome disks
  #     "ssd" # optimize for ssd
  #     #"noatime" # doesn't write access time to files
  #     "compress-force=zstd:3" # compression level 5, good for slow drives. forces compression of every file even if fails to compress first segment of the file
  #     # "ssd" # optimize for an ssd
  #     # security "nosuid" "nodev" (https://serverfault.com/questions/547237/explanation-of-nodev-and-nosuid-in-fstab)
  #   ];
  # };

  fileSystems."/" =
    { device = "/dev/nvme0n1p5";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "defaults"
        "x-gvfs-show" # show in gnome disks
        "ssd" # optimize for ssd
        #"noatime" # doesn't write access time to files
        "compress-force=zstd:3" # compression level 5, good for slow drives. forces compression of every file even if fails to compress first segment of the file
        # "ssd" # optimize for an ssd
        # security "nosuid" "nodev" (https://serverfault.com/questions/547237/explanation-of-nodev-and-nosuid-in-fstab)
      ];
    };
  # hide the partitions from nautilus
  services.udev.extraRules = ''
    # Hide /dev/nvme0n1p5 by its kernel name
    KERNEL=="nvme0n1p5", ENV{UDISKS_IGNORE}="1"

    # Hide /dev/sda1 by its kernel name
    KERNEL=="sda1", ENV{UDISKS_IGNORE}="1"

    # Hide a partition by its UUID
    ENV{ID_FS_UUID}=="2dff5eb1-1dce-46fd-a0cc-510e5dd3b666", ENV{UDISKS_IGNORE}="1"
  '';

  fileSystems."/nix" =
    { device = "/dev/nvme0n1p5";
      fsType = "btrfs";
      options = [ 
        "subvol=@nix" 
        "defaults"
        "ssd" # optimize for ssd
        #"noatime" # doesn't write access time to files
        "compress-force=zstd:3"
        ];
    };

  fileSystems."/persistent" =
    { device = "/dev/nvme0n1p5";
      fsType = "btrfs";
      options = [ 
        "subvol=@persistent" 
        "defaults"
        "ssd" # optimize for ssd
        #"noatime" # doesn't write access time to files
        "compress-force=zstd:3"
        ];
    };

  fileSystems."/swap" =
    { device = "/dev/nvme0n1p5";
      fsType = "btrfs";
      options = [ 
        "subvol=@swap" 
        "defaults"
        "ssd" # optimize for ssd
      ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/BB10-773E"; # BB10-773E"; A665-64BE
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" "defaults" ];
    };

  # fileSystems."/" =
  #   { device = "/dev/nvme0n1p5";
  #     fsType = "btrfs";
  #     options = [
  #       "subvol=@"
  #       "defaults"
  #       "x-gvfs-show" # show in gnome disks
  #       "ssd" # optimize for ssd
  #       #"noatime" # doesn't write access time to files
  #       "compress-force=zstd:3" # compression level 5, good for slow drives. forces compression of every file even if fails to compress first segment of the file
  #       # "ssd" # optimize for an ssd
  #       # security "nosuid" "nodev" (https://serverfault.com/questions/547237/explanation-of-nodev-and-nosuid-in-fstab)
  #     ];
  #   };

  # fileSystems."/nix" =
  #   { device = "/dev/nvme0n1p5";
  #     fsType = "btrfs";
  #     options = [ 
  #       "subvol=@nix" 
  #       "defaults"
  #       "ssd" # optimize for ssd
  #       #"noatime" # doesn't write access time to files
  #       "compress-force=zstd:3"
  #       ];
  #   };

  # fileSystems."/persistent" =
  #   { device = "/dev/nvme0n1p5";
  #     fsType = "btrfs";
  #     options = [ 
  #       "subvol=@persistent" 
  #       "defaults"
  #       "ssd" # optimize for ssd
  #       #"noatime" # doesn't write access time to files
  #       "compress-force=zstd:3"
  #       ];
  #   };

  # fileSystems."/swap" =
  #   { device = "/dev/nvme0n1p5";
  #     fsType = "btrfs";
  #     options = [ 
  #       "subvol=@swap" 
  #       "defaults"
  #       "ssd" # optimize for ssd
  #     ];
  #   };

  # fileSystems."/boot" =
  #   { device = "/dev/disk/by-uuid/A665-64BE";
  #     fsType = "vfat";
  #     options = [ "fmask=0022" "dmask=0022" ];
  #   };

  # #fileSystems."/boot/efi" = {
  # #  device = "/dev/disk/by-uuid/A665-64BE";
  # #  fsType = "vfat";
  # #};

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # #     _____                            _               _____                 _  __ _         _____             __ _       
  # #    / ____|                          | |             / ____|               (_)/ _(_)       / ____|           / _(_)      
  # #   | |     ___  _ __ ___  _ __  _   _| |_ ___ _ __  | (___  _ __   ___  ___ _| |_ _  ___  | |     ___  _ __ | |_ _  __ _ 
  # #   | |    / _ \| '_ ` _ \| '_ \| | | | __/ _ \ '__|  \___ \| '_ \ / _ \/ __| |  _| |/ __| | |    / _ \| '_ \|  _| |/ _` |
  # #   | |___| (_) | | | | | | |_) | |_| | ||  __/ |     ____) | |_) |  __/ (__| | | | | (__  | |___| (_) | | | | | | | (_| |
  # #    \_____\___/|_| |_| |_| .__/ \__,_|\__\___|_|    |_____/| .__/ \___|\___|_|_| |_|\___|  \_____\___/|_| |_|_| |_|\__, |
  # #                         | |                               | |                                                      __/ |
  # #                         |_|                               |_|                                                     |___/ 
  # #   Not Generated by `nixos-generate-config`

  # swap in btrfs as followed from https://nixos.wiki/wiki/Btrfs#:~:text=btrfs%20is%20a%20modern%20copy,tolerance,%20repair%20and%20easy%20administration.
  swapDevices = [
    #{ device = "/swap/swapfile"; size = 1*1024; 
    #  priority = 0; # Higher numbers indicate higher priority.
    #}
    {
      device = "/dev/disk/by-label/DataDiskSwap";
      priority = 2; # Higher numbers indicate higher priority.
      # This needs to be higher, so hibernation works, systemd only checks the swap device with more priority (https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1910252)
      options = [ "nofail" ];
    }
  ];

  # # MY MOUNTS
  # fileSystems."/mnt/DataDisk" = {
  #   device = "/dev/disk/by-label/DataDisk";
  #   fsType = "lowntfs-3g";
  #   options = [
  #     "uid=1000" "gid=1000" "rw" "exec" "umask=000" # "user"
  #     # gaming options as per valve: https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows
  #     # "ignore_case" # prevents you from making any file or directory with any upper case letter... only lowntfs-3g might help some games
  #     "x-gvfs-show"
  #     #"windows_names" # makes games not work
  #     "nofail"
  #     /*
  #     "defaults"
  #     # "nosuid" "nodev" # security, probably should
  #     "nofail"
  #     "x-gvfs-show"
  #     "windows_names"
  #     "big_writes"
  #     "streams_interface=windows" # only ntfs-3g 
  #     "nls=utf8" */
  #   ];
  # };
  fileSystems."/mnt/hdd-ntfs" = {
    device = "/dev/disk/by-label/hdd-ntfs";
    fsType = "lowntfs-3g";
    options = [
      "uid=1000" "gid=1000" "rw" "exec" "umask=000" # "user"
      # gaming options as per valve: https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows
      # "ignore_case" # prevents you from making any file or directory with any upper case letter... only lowntfs-3g might help some games
      "x-gvfs-show"
      #"windows_names" # makes games not work
      "nofail"
      /*
      "defaults"
      # "nosuid" "nodev" # security, probably should
      "nofail"
      "x-gvfs-show"
      "windows_names"
      "big_writes"
      "streams_interface=windows" # only ntfs-3g 
      "nls=utf8" */
    ];
  };
  fileSystems."/mnt/hdd-btrfs" = {
    device = "/dev/disk/by-label/hdd-btrfs";
    fsType = "btrfs";
    options = [
      "defaults"
      "nofail" # boots anyways if can't find the disk 
      "x-gvfs-show" # show in gnome disks
      #"noatime" # doesn't write access time to files
      "compress-force=zstd:5" # compression level 3, good for slow drives. forces compression of every file even if fails to compress first segment of the file
      # "ssd" # optimize for an ssd
      # security "nosuid" "nodev" (https://serverfault.com/questions/547237/explanation-of-nodev-and-nosuid-in-fstab)
    ];
  };
  fileSystems."/mnt/hdd-ext4" = {
    device = "/dev/disk/by-label/hdd-ext4";
    fsType = "ext4";
    options = [
      "nosuid"
      "nodev"
      "nofail"
      "x-gvfs-show"
    ];
  };
}
