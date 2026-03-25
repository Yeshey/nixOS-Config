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
      nvitopDesktop = pkgs.makeDesktopItem {
        name = "nvitop";
        desktopName = "NVITOP";
        comment = "NVIDIA GPU monitoring (nvitop)";
        exec = "nvitop";
        icon = "org.gnome.SystemMonitor";
        categories = [ "System" "Monitor" "ConsoleOnly" ];
        terminal = true;
      };
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

      services.udev.extraRules = ''
        KERNEL=="nvme0n1p5", ENV{UDISKS_IGNORE}="1"
        KERNEL=="sda1", ENV{UDISKS_IGNORE}="1"
        ENV{ID_FS_UUID}=="2dff5eb1-1dce-46fd-a0cc-510e5dd3b666", ENV{UDISKS_IGNORE}="1"
      '';

      fileSystems."/" = {
        device = "/dev/nvme0n1p5";
        fsType = "btrfs";
        options = [ "subvol=@" "defaults" "x-gvfs-show" "ssd" "compress-force=zstd:3" ];
      };
      fileSystems."/nix" = {
        device = "/dev/nvme0n1p5";
        fsType = "btrfs";
        options = [ "subvol=@nix" "defaults" "ssd" "compress-force=zstd:3" ];
      };
      fileSystems."/persistent" = {
        device = "/dev/nvme0n1p5";
        fsType = "btrfs";
        neededForBoot = true;
        options = [ "subvol=@persistent" "defaults" "ssd" "compress-force=zstd:3" ];
      };
      fileSystems."/swap" = {
        device = "/dev/nvme0n1p5";
        fsType = "btrfs";
        options = [ "subvol=@swap" "defaults" "ssd" ];
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/BB10-773E";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" "defaults" ];
      };

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

      virtualisation.docker.storageDriver = "btrfs";

      security.tpm2 = {
        enable = true;
        pkcs11.enable = true;
        tctiEnvironment.enable = true;
      };

      hardware.nvidia-container-toolkit.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];
      environment.systemPackages = with pkgs; [
        # NVIDIA
        cudaPackages.cudatoolkit # for blender (nvidia)
        nvitop # so good to view GPU usage
        nvitopDesktop
        # gwe?
      ];
      hardware.nvidia = {
        open = false; # my GPU is listed under compatible GPUs: https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
        #package = config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = true;
        # nvidiaPersistenced = true; # It ensures all GPUs stay awake even during headless mode.
        powerManagement.enable = true; # Experimental power management through systemd
        powerManagement.finegrained = false;
        prime = {
          # sync.enable = true; # gpu always # https://github.com/NixOS/nixpkgs/issues/199024#issuecomment-1300650034 # does not work with GPU passthrough
          offload.enable = true; # gpu on demand # works with GPU passthrough
          intelBusId = "PCI:0:2:0"; # "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0"; # "PCI:1:0:0";
        };
      };
    };
}