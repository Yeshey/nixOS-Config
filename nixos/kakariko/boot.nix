{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:

let
  
in
{
  imports = [
    # https://discourse.nixos.org/t/a-modern-and-secure-desktop-setup/41154
    #inputs.lanzaboote.nixosModules.lanzaboote
  ];

  /*
  # secure boot is a little too complicated
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };*/

  # https://discourse.nixos.org/t/how-do-i-mount-multiple-bcachefs-devices-on-boot/37463
  /*
  systemd.services.mount-root = {
    description = "Mount root bcachefs filesystem";
    # Bind to the specific device units
    bindsTo = [ "dev-nvme0n1p5.device" "dev-sdb3.device" ];
    # Specify ordering dependencies
    after = [ "dev-nvme0n1p5.device" "dev-sdb3.device" "local-fs-pre.target" ];
    requires = [ "dev-nvme0n1p5.device" "dev-sdb3.device" ];
    before = [ "umount.target" "local-fs.target" ];
    # Unit configuration to manage dependencies and disable default dependencies
    unitConfig = {
      RequiresMountsFor = "/";
      DefaultDependencies = false;
    };
    # Service configuration
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Mount the root filesystem
      ExecStart = "${pkgs.util-linux}/bin/mount -o noatime,nodev,nosuid,noexec -t bcachefs /dev/nvme0n1p5:/dev/sdb3 /";
      # Unmount the filesystem on service stop
      ExecStop = "${pkgs.util-linux}/bin/umount /";
    };
    # Ensure the service is started during the multi-user runlevel
    wantedBy = [ "multi-user.target" ];
  };
*/

  # with .SSD..?
  # Ensure the mount point for bcachefs exists
  /*
  environment.etc."home/yeshey/.SSD".text = "";
  # Custom systemd service to mount the multi-device bcachefs filesystem
  systemd.services.mount-bcachefs = {
    description = "Mount bcachefs filesystem";
    # Bind to the specific device units
    bindsTo = [ "dev-nvme0n1p5.device" "dev-sdb3.device" ];
    # Specify ordering dependencies
    after = [ "dev-nvme0n1p5.device" "dev-sdb3.device" "local-fs-pre.target" ];
    requires = [ "dev-nvme0n1p5.device" "dev-sdb3.device" ];
    before = [ "umount.target" "local-fs.target" ];
    # Unit configuration to manage dependencies and disable default dependencies
    unitConfig = {
      RequiresMountsFor = "/home/yeshey/.SSD";
      DefaultDependencies = false;
    };
    # Service configuration
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Create the mount point before attempting to mount
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/yeshey/.SSD";
      # Mount the bcachefs filesystem with specified options
      ExecStart = "${pkgs.util-linux}/bin/mount -o noatime,nodev,nosuid,noexec -t bcachefs /dev/nvme0n1p5:/dev/sdb3 /home/yeshey/.SSD";
      # Unmount the filesystem on service stop
      ExecStop = "${pkgs.util-linux}/bin/umount /home/yeshey/.SSD";
    };
    # Ensure the service is started during the multi-user runlevel
    wantedBy = [ "multi-user.target" ];
  };*/

  /*
# normal service that doesnt work
[Unit]
After=dev-nvme0n1p5.device dev-sdb3.device local-fs-pre.target
Before=umount.target local-fs.target
BindsTo=dev-nvme0n1p5.device dev-sdb3.device
DefaultDependencies=false
Description=Mount root bcachefs filesystem
Requires=dev-nvme0n1p5.device dev-sdb3.device
RequiresMountsFor=/

[Service]
Environment="LOCALE_ARCHIVE=/nix/store/jaxjp1xl030ww8a0p0967bn4fs1r9bc7-glibc-locales-2.40-36/lib/locale/locale-archive"
Environment="PATH=/nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin:/nix/store/w8pnfazxqwmrqmwkb5zrz1bifsd8abxl-findutils-4.10.0/bin:/nix/store/85amyk92rg19l4fy0qmy7wr4jmq8p5z0-gnugrep-3.11/bin:/nix/store/vmby25zqxnx94awvj0k7zn0rsd0zyrwg-gnused-4.9/bin:/nix/store/3abwqv1a1bdycmgaydzfw3a0qzxwk8am-systemd-256.8/bin:/nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/sbin:/nix/store/w8pnfazxqwmrqmwkb5zrz1bifsd8abxl-findutils-4.10.0/sbin:/nix/store/85amyk92rg19l4fy0qmy7wr4jmq8p5z0-gnugrep-3.11/sbin:/nix/store/vmby25zqxnx94awvj0k7zn0rsd0zyrwg-gnused-4.9/sbin:/nix/store/3abwqv1a1bdycmgaydzfw3a0qzxwk8am-systemd-256.8/sbin"
Environment="TZDIR=/nix/store/dfsiy184c8z6gf5x6cqfyahxv9g16828-tzdata-2024b/share/zoneinfo"
ExecStart=/nix/store/ndqpb82si5a7znlb4wa84sjncl4mvgqm-util-linux-2.39.4-bin/bin/mount -o noatime,nodev,nosuid,noexec -t bcachefs /dev/nvme0n1p5:/dev/sdb3 /
ExecStop=/nix/store/ndqpb82si5a7znlb4wa84sjncl4mvgqm-util-linux-2.39.4-bin/bin/umount /
RemainAfterExit=true
Type=oneshot

[Install]
WantedBy=multi-user.target

  */


  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;  # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
  security.tpm2.tctiEnvironment.enable = true;  # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/84A9-3C95";
      fsType = "vfat";
      #options = [ "fmask=0022" "dmask=0022" ]; 
      # ⚠️ fix the security issue ⚠️
      # https://github.com/NixOS/nixpkgs/issues/279362#issuecomment-1883970541
      options = [ "uid=0" "gid=0" "fmask=0077" "dmask=0077" ];
    };

  # Bootloader.
  #boot.loader.systemd-boot = {
  #  enable = true;
  #  configurationLimit = 10; # You can leave it null for no limit, but it is not recommended, as it can fill your boot partition.
  #};
  #boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot";

  
  boot.loader = {
    timeout = 5;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      # version = 2;
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
  

  # boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.systemd.emergencyAccess = true;

  boot.supportedFilesystems = [ "bcachefs" ];

  boot.initrd.preLVMCommands = lib.mkOrder 400 "sleep 7"; # in my case I had to wait a bit to let my hardware pick up on my microSD
  # Root filesystem with bcachefs
  fileSystems."/" =
    { #device = "/dev/nvme0n1p5:/dev/sdb3";
      device = "UUID=29164f68-4557-481f-a0e0-21bf4b095153";
      fsType = "bcachefs";
      options = [
        "errors=ro" "noatime" "nodiratime"
        "replicas=1"
        "foreground_target=/dev/nvme0n1p5"
        "background_target=/dev/sdb3"
        "promote_target=/dev/nvme0n1p5"
        "compression=zstd:1"
        "background_compression=zstd:6"
      ];
    };

  swapDevices =
    [ 
      {
        device = "/dev/disk/by-label/swap-microsd";
        priority = 0; # Higher numbers indicate higher priority.
      }
      { 
        device = "/dev/disk/by-label/swap-nvme";
        priority = 1; # Higher numbers indicate higher priority.
      }
    ];
  # MY MOUNTS
  fileSystems."${config.mySystem.dataStoragePath}" = {
    device = "/dev/disk/by-label/btrfsMicroSD-DataDisk";
    fsType = "btrfs";
    options = [ # check mount options of mounted btrfs fs: sudo findmnt -t btrfs
      "defaults"
      "nofail" # boots anyways if can't find the disk 
      # "users" # any user can mount
      "x-gvfs-show" # show in gnome disks
      #"noatime" # doesn't write access time to files
      "compress-force=zstd:5" # compression level 5, good for slow drives. forces compression of every file even if fails to compress first segment of the file
      # "ssd" # optimize for an ssd
      # security "nosuid" "nodev" (https://serverfault.com/questions/547237/explanation-of-nodev-and-nosuid-in-fstab)
    ];
  };

/*
findmnt -t btrfs 
TARGET                       SOURCE                           FSTYPE OPTIONS
/                            /dev/dm-6                        btrfs  rw,relatime,compress=zstd:3,space_cache=v2,subvolid=5,subvol=/
├─/mnt/btrfsMicroSD-DataDisk /dev/sda2                        btrfs  rw,nodev,relatime,space_cache,subvolid=5,subvol=/
├─/nix/store                 /dev/dm-6[/nix/store]            btrfs  ro,relatime,compress=zstd:3,space_cache=v2,subvolid=5,subvol=/
└─/var/lib/docker/btrfs      /dev/dm-6[/var/lib/docker/btrfs] btrfs  rw,relatime,compress=zstd:3,space_cache=v2,subvolid=5,subvol=/
*/

}
