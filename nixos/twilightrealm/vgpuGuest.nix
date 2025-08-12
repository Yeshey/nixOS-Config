# thanks to https://github.com/MakiseKurisu/nixos-config/blob/main/modules/nvidia-vgpu.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.vgpu4nixos.nixosModules.guest
    inputs.fastapi-dls-nixos.nixosModules.default
  ];

  mySystem.hardware.nvidia = {
    enable = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_6;
  };

  # https://docs.nvidia.com/vgpu/latest/pdf/grid-vgpu-user-guide.pdf
  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.grid_17_3;
      open = lib.mkForce false;
      vgpu.patcher.enable = true;
    };
  };

  programs.mdevctl = {
    enable = true;
  };

}

