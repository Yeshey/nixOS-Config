{
  flake.modules.nixos.skyloft =
    { modulesPath, ... }:
    {
      imports =
        [ (modulesPath + "/profiles/qemu-guest.nix")
        ];

      boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_pci" "virtio_scsi" "usbhid" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

      swapDevices = [
        { device = "/swap/swapfile"; size = 4*1024; 
          priority = 0; # Higher numbers indicate higher priority.
        }
      ];
    };
}