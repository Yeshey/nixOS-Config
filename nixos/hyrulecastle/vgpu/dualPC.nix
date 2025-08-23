# if windows 11 isnt working, remove loader and nvram tags from windows 11 xml config
# thanks to https://github.com/MakiseKurisu/nixos-config/blob/main/modules/nvidia-vgpu.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{

  boot.kernelParams = [
    "intel_iommu=on"
    "kvm.ignore_msrs=1"
    "iommu=pt"
  ];

  boot.kernelModules = [
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"

    "nvidia-vgpu-vfio"
  ];

  users.groups.libvirtd.members = [ "root" "yeshey" ];

  boot.extraModprobeConfig = 
    ''    
    options nvidia vup_sunlock=1 vup_swrlwar=1 vup_qmode=1
    ''; # (for driver 535) bypasses `error: vmiop_log: NVOS status 0x1` in nvidia-vgpu-mgr.service when starting VM
  # environment.etc."nvidia-vgpu-xxxxx/vgpuConfig.xml".source = config.hardware.nvidia.package + /vgpuConfig.xml;

}

