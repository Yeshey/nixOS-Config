# thanks to https://github.com/MakiseKurisu/nixos-config/blob/main/modules/nvidia-vgpu.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config.mySystem.guestVgpu; # TODO make it a specialization
in
{
  imports = [
    inputs.vgpu4nixos.nixosModules.guest
    inputs.fastapi-dls-nixos.nixosModules.default
  ];

  options.mySystem.guestVgpu = {
    enable = lib.mkEnableOption "guestVgpu";
  };

  config = lib.mkIf cfg.enable {

    mySystem.hardware.nvidia = {
      enable = lib.mkForce true;
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
        # driverSource = {
        #   name  = "cuda_nvcc-linux-x86_64-12.8.61-archive.tar.xz";
        #   url   = "file://${gdown-fetch { name = "cuda_nvcc-linux-x86_64-12.8.61-archive.tar.xz"; id = fileId; inherit sha256; }}";
        #   sha256 = sha256;
        # };
      };
    };

    programs.mdevctl = {
      enable = true;
    };

  };
}

