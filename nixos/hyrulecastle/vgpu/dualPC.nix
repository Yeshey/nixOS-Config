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
    "iommu=pt"
  ];

  # Bind the GPU and its audio function to vfio-pci so vGPU stub can work
  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:1f11,10de:10f9
  '';

}