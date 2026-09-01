{
  flake.modules.nixos.onikao =
    { modulesPath, lib, config, ... }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

       swapDevices = [ {
         device = "/var/lib/swapfile";
         size = 16 * 1024; # 16GB
       } ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/e98cec98-723a-43b1-b0ed-d381a286c6a1";
        fsType = "btrfs";
        options = [ "subvol=root" ];  # confirm subvol name, generator omitted it
      };

      fileSystems."/home" = {
        device = "/dev/disk/by-uuid/e98cec98-723a-43b1-b0ed-d381a286c6a1";
        fsType = "btrfs";
        options = [ "subvol=home" ];
      };

      fileSystems."/nix" = {
        device = "/dev/disk/by-uuid/e98cec98-723a-43b1-b0ed-d381a286c6a1";
        fsType = "btrfs";
        options = [ "subvol=nix" ];
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/F119-B73A";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}