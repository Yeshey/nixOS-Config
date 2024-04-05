# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, dataStoragePath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "dm-cache" "dm-cache-smq" "dm-cache-mq" "dm-cache-cleaner" ];
  boot.kernelModules = [ "coretemp" "kvm-intel" "kvm-amd" "dm-cache" "dm-cache-smq" "dm-persistent-data" "dm-bio-prison" "dm-clone" "dm-crypt" "dm-writecache" "dm-mirror" "dm-snapshot" ]; # "coretemp" for temp sensors
  boot.extraModulePackages = [ ];

  # for LVM: (https://github.com/NixOS/nixpkgs/issues/15516)
  services.lvm.boot.thin.enable = true;

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/84A9-3C95";
      fsType = "vfat";
    };
/*fileSystems."/" =
    { device = "/dev/disk/by-label/NixOS";
      fsType = "ext4";
    }; */
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/c0d72823-1159-4eef-a4ba-f50c443aff6b"; 
      #sudo blkid /dev/VG/root
      #device = "/dev/disk/by-label/root";
      fsType = "ext4";
    };

  # nixos-generate-config Auto Generated cache config: # this is a bug..?
/*fileSystems."/nix/store" =
    { device = "/nix/store";
      fsType = "none";
      options = [ "bind" ];
    };
  fileSystems."/root/.cache/doc" =
    { device = "portal";
      fsType = "fuse.portal";
    };
  fileSystems."/root/.cache/gvfs" =
    { device = "gvfsd-fuse";
      fsType = "fuse.gvfsd-fuse";
    }; */

  # MY MOUNTS
  fileSystems."${dataStoragePath}" = {
    device = "/dev/disk/by-label/ntfsMicroSD-DataDisk";
    fsType = "auto";
    options = [ "nodev" "nofail" "x-gvfs-show"   ]; #"uid=1000" "gid=1000" "dmask=007" "fmask=117"
  };

  swapDevices = [{ device = "/dev/disk/by-uuid/3d28629e-2f9b-4ae5-93b1-2a1018faeed3"; }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
 
}
