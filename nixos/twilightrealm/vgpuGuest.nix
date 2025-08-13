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
      enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    boot = {
      kernelPackages = pkgs.linuxPackages_6_6;
    };


    programs.mdevctl = {
      enable = true;
    };

  };
}

