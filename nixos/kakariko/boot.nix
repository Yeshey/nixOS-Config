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
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10; # You can leave it null for no limit, but it is not recommended, as it can fill your boot partition.
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.systemd.emergencyAccess = true;

  boot.supportedFilesystems = [ "bcachefs" ];

  # Root filesystem with bcachefs
  fileSystems."/" = {
    device = "/dev/nvme0n1p5:/dev/sdb3";
    fsType = "bcachefs";
    options = [
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
