{
  inputs,
  pkgs,
  lib,
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
  # Using secure boot now
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10; # You can leave it null for no limit, but it is not recommended, as it can fill your boot partition.
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.enableTpm2 = true;
  boot.initrd.systemd.emergencyAccess = true;
  #security.tpm2.enable = true;
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/VG/cryptroot";
  };
  boot.initrd.luks.devices.cryptswap = {
    device = "/dev/VG/cryptswap";
  };

  fileSystems."/" =
    { #device = "/dev/disk/by-uuid/6e60cc35-882f-45bf-8402-719a14a74a74";
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "compress=zstd" ];
    };
  swapDevices =
    [ 
      { #device = "/dev/disk/by-uuid/aea2ed46-641d-4fe5-8551-880c8a8a034f"; 
        device = "/dev/disk/by-label/swap";
        priority = 1; # Higher numbers indicate higher priority.
      }
      { device = "/var/swapfile"; size = 7*1024; 
        priority = 0; # Higher numbers indicate higher priority.
      }
    ];
  # MY MOUNTS
  fileSystems."/mnt/ntfsMicroSD-DataDisk" = {
    device = "/dev/disk/by-label/ntfsMicroSD-DataDisk";
    fsType = "auto";
    options = [
      "nodev"
      "nofail"
      "x-gvfs-show"
    ]; # "uid=1000" "gid=1000" "dmask=007" "fmask=117"
  };
}
