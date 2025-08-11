# thanks to https://github.com/MakiseKurisu/nixos-config/blob/main/modules/nvidia-vgpu.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config.mySystemHyruleCastle.vgpu; # TODO make it a specialization
  gdown-fetch = import ./gdown-fetch.nix { inherit pkgs; };
  fileId = "1FOD_q0ZA04i9IqaoFEB8I7wcVkPBkkqT";
  sha256 = "sha256-vBsxP1/SlXLQEXx70j/g8Vg/d6rGLaTyxsQQ19+1yp0=";
in
{
  
  options.mySystemHyruleCastle.vgpu = {
    enable = lib.mkEnableOption "NvidiaVgpuSharing";
  };

  config = lib.mkIf cfg.enable {
    specialisation."vgpu".configuration = { config, pkgs, lib, ... }: {
        imports = [
          inputs.vgpu4nixos.nixosModules.host
          inputs.fastapi-dls-nixos.nixosModules.default
          ./dualPC.nix
        ];
      environment.etc.specialisation.text = "vgpu";
      system.nixos.tags = [ "vgpu" ];

    boot = {
      kernelPackages = pkgs.linuxPackages_6_6;
    };

    # https://docs.nvidia.com/vgpu/latest/pdf/grid-vgpu-user-guide.pdf
    hardware = {
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.vgpu_17_3;
        open = lib.mkForce false;
        vgpu = {
          patcher = {
            enable = true;
            options.doNotForceGPLLicense = true;
            # runtimeOptions.enable = true;
            copyVGPUProfiles = {
              "1E93:0000" = "1E30:12BA"; # GeForce RTX 2080 SUPER Mobile / Max-Q
              "1E07:0000" = "1E30:12BA"; # GeForce RTX 2080 Ti Rev. A
            };
            profileOverrides = {
              # GRID RTX6000-1Q
              "256" = {
                vramAllocation = 1024;
                heads = 4;
                enableCuda = true;
                display = {
                  width = 7680;
                  height = 4320;
                };
                framerateLimit = 0;
              };
              # GRID RTX6000-6Q
              "260" = {
                vramAllocation = 6144;
                heads = 4;
                enableCuda = true;
                display = {
                  width = 7680;
                  height = 4320;
                };
                framerateLimit = 0;
              };
              # GRID RTX6000-24Q
              "263" = {
                vramAllocation = 16384;
                heads = 4;
                enableCuda = true;
                display = {
                  width = 7680;
                  height = 4320;
                };
                framerateLimit = 0;
              };
            };
          };
          driverSource = {
            name  = "NVIDIA-Linux-x86_64-550.90.05-vgpu-kvm.run";
            url   = "file://${gdown-fetch { name = "NVIDIA-Linux-x86_64-550.90.05-vgpu-kvm.run"; id = fileId; inherit sha256; }}";
            sha256 = sha256;
          };
        };
      };
    };

    programs.mdevctl = {
      enable = true;
    };
    };
  };
}
