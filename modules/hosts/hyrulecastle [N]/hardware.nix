{ inputs, ... }:
{
  flake.modules.nixos.hyrulecastle =
    { config, lib, pkgs, modulesPath, ... }:
    let
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
      hdaJackRetaskFwPkg = pkgs.runCommand "hda-jack-retask-custom-fw" { } ''
        mkdir -p $out/lib/firmware
        echo "${hdaJackRetaskFwContent}" > $out/lib/firmware/hda-jack-retask.fw
      '';
    in
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.nixos-hardware.nixosModules.common-cpu-intel
        inputs.nixos-hardware.nixosModules.common-pc-ssd
      ];

      boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];
      boot.kernelParams = [ "i915.force_probe=46a6" ];

      swapDevices = [{
        device = "/dev/disk/by-label/DataDiskSwap";
        priority = 2;
        options = [ "nofail" ];
      }];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      hardware.firmware = [ hdaJackRetaskFwPkg ];
      boot.extraModprobeConfig = ''
        options snd-hda-intel patch=hda-jack-retask.fw
      '';

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [ libva-vdpau-driver libvdpau-va-gl ];
      };
    };
}