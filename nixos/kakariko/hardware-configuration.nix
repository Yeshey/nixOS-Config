# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod"  "ahci" "ehci_pci" "usbhid" "sr_mod" ];
  boot.initrd.kernelModules = [ 
"dm-snapshot" 
"usb_storage" 
"sd_mod"
 "ehci_pci" 
"ohci_pci" 
"usbhid" 
"ahci"
 "sata_nv"
 "dm_mod" 
"dm_crypt" 
"cryptd" 
"xhci_hcd"   
"dm-cache" 
"dm-cache-smq" 
"dm-cache-mq" 
"dm-cache-cleaner" 
] ++ config.boot.initrd.luks.cryptoModules;
  boot.kernelModules = [ "kvm-intel" "dm_mod" "dm_crypt" "uas" "dm-cache" "dm-cache-smq"   "kvm-amd" "dm-persistent-data" "dm-bio-prison" "dm-clone" "dm-crypt" "dm-writecache" "dm-mirror" "dm-snapshot"];
  boot.kernelParams = [ "boot.shell_on_fail" ];
  boot.extraModulePackages = [ ];

	services.lvm.boot.thin.enable = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/6e60cc35-882f-45bf-8402-719a14a74a74";
      fsType = "btrfs";
    };

boot.initrd.preLVMCommands = lib.mkOrder 400 "sleep 5";

  boot.initrd.luks.devices = {
    "cryptroot" = {
      device = "/dev/VG/cryptroot";
      allowDiscards = true; # for ssd primary?
      preLVM = false; # informs that its LUKS on LVM and not LVM on LUKS
    };
    "cryptswap" = {
      device = "/dev/VG/cryptswap";
      allowDiscards = true; # for ssd primary?
      preLVM = false; # informs that its LUKS on LVM and not LVM on LUKS
    };
  }; 

#boot.initrd.preLVMCommands = ''
#for i in {1..10}; do
#    lvm vgchange -ay && break || sleep 1
#  done
#	lvm vgchange -ay
#'';

/*
  boot.initrd.luks.devices."cryptroot" = {
	device = "/dev/disk/by-uuid/f2f81395-c2ab-4d5b-9e8c-4be604077b55";
	#device = "5EBMaS-v0AP-d1jw-zLOZ-x0dF-w41g-WJJtXu";
	preLVM = false;
	#allowDiscards = true;
};*/

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/84A9-3C95";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices =
    [ #{ device = "/dev/disk/by-uuid/9ad37198-50fd-4c0e-9e1b-7bf5d0aeabe6"; }
      { device = "/dev/mapper/cryptswap"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}