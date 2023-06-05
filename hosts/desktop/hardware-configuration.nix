# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, dataStoragePath, ... }:

let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [ "i915.force_probe=46a6" ]; #"i915.force_probe=46a6"

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/69e9ba80-fb1f-4c2d-981d-d44e59ff9e21";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd" "noatime" ];
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/A665-64BE";
      fsType = "vfat";
    };

  fileSystems."/swap" =
    { device = "/dev/disk/by-uuid/69e9ba80-fb1f-4c2d-981d-d44e59ff9e21";
      fsType = "btrfs";
      options = [ "subvol=swap" "nofail"];
    };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

#     _____                            _               _____                 _  __ _         _____             __ _       
#    / ____|                          | |             / ____|               (_)/ _(_)       / ____|           / _(_)      
#   | |     ___  _ __ ___  _ __  _   _| |_ ___ _ __  | (___  _ __   ___  ___ _| |_ _  ___  | |     ___  _ __ | |_ _  __ _ 
#   | |    / _ \| '_ ` _ \| '_ \| | | | __/ _ \ '__|  \___ \| '_ \ / _ \/ __| |  _| |/ __| | |    / _ \| '_ \|  _| |/ _` |
#   | |___| (_) | | | | | | |_) | |_| | ||  __/ |     ____) | |_) |  __/ (__| | | | | (__  | |___| (_) | | | | | | | (_| |
#    \_____\___/|_| |_| |_| .__/ \__,_|\__\___|_|    |_____/| .__/ \___|\___|_|_| |_|\___|  \_____\___/|_| |_|_| |_|\__, |
#                         | |                               | |                                                      __/ |
#                         |_|                               |_|                                                     |___/ 
#   Not Generated by `nixos-generate-config`

  # SWAP
  # swap in ext4:
  #swapDevices = [ {
  #  device = "/var/lib/swapfile";
  #  size = 17*1024;
  #} ];
  # swap in btrfs as followed from https://nixos.wiki/wiki/Btrfs#:~:text=btrfs%20is%20a%20modern%20copy,tolerance,%20repair%20and%20easy%20administration.
  swapDevices = [ 
    {
      device = "/mnt/hdd-btrfs/swap/swaphdd";
      priority = 0; # Higher numbers indicate higher priority.
      options = [ "nofail"];
    }
    { 
      device = "/swap/swapfile";
      priority = 1; # Higher numbers indicate higher priority.
    }
    { 
      device = "/dev/disk/by-label/DataDiskSwap"; 
      priority = 2; # Higher numbers indicate higher priority.
      # This needs to be higher, so hibernation works, systemd only checks the swap device with more priority (https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1910252)
      options = [ "nofail"];
    }
  ];

  # MY MOUNTS
  fileSystems."${dataStoragePath}" = {
    device = "/dev/disk/by-label/DataDisk";
    fsType = "auto";
    options = [ "nosuid" "nodev" "nofail" "x-gvfs-show" "defaults" "users" "windows_names" "big_writes" "streams_interface=windows" "nls=utf8" ]; # x-systemd.device-timeout=3s
  };
  fileSystems."/mnt/hdd-ntfs" = {
    device = "/dev/disk/by-label/hdd-ntfs";
    fsType = "auto";
    options = [ "nosuid" "nodev" "nofail" "x-gvfs-show" "defaults" "users" "windows_names" "big_writes" "streams_interface=windows" "nls=utf8" ]; # "uid=1000" "gid=1000" "dmask=027" "fmask=137" # defaults,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000,windows_names [ "uid=1000" "gid=1000" "dmask=007" "fmask=117" "nofail"]; norecover,big_writes,streams_interface=windows,inherit
  };
  fileSystems."/mnt/hdd-btrfs" = {
    device = "/dev/disk/by-label/hdd-btrfs";
    fsType = "btrfs";
    options = [ "nosuid" "nodev" "nofail" "x-gvfs-show" ];
  };
  fileSystems."/mnt/hdd-ext4" = {
    device = "/dev/disk/by-label/hdd-ext4";
    fsType = "ext4";
    options = [ "nosuid" "nodev" "nofail" "x-gvfs-show" ];
  };

  # NVIDIA
  # Allow unfree packages
  nixpkgs.config = {
    cudaSupport = true; # for blender (nvidia)
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "nvidia-x11"
    "nvidia-settings"
  ];
  environment.systemPackages = with pkgs; [
    # NVIDIA
    cudaPackages.cudatoolkit # for blender (nvidia)
    nvidia-offload
  ];
  # NVIDIA drivers 
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  # Comment this to use only the nvidia Grpahics card (discrete graphics option in BIOS instead of switchable graphics)
  hardware.nvidia = {
    #package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    # nvidiaPersistenced = true; # It ensures all GPUs stay awake even during headless mode.
    powerManagement.enable = true; # Experimental power management through systemd
    prime = {
      sync.enable = true; # gpu always # https://github.com/NixOS/nixpkgs/issues/199024#issuecomment-1300650034 # does not work with GPU passthrough
      #offload.enable = true; # gpu on demand # works with GPU passthrough
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  # required for external monitor usage on nvidia offload (or not?)
  specialisation = {
    external-display.configuration = {
      system.nixos.tags = [ "external-display" ];
      hardware.nvidia.prime.offload.enable = lib.mkForce false;
      hardware.nvidia.powerManagement.enable = lib.mkForce false;
    };
  };


}
