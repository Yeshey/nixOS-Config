{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mySystemHyruleCastle.vgpu; # TODO make it a specialization

  # need to pin because of this error: https://discourse.nixos.org/t/cant-update-nvidia-driver-on-stable-branch/39246
  inherit (pkgs.stdenv.hostPlatform) system;
  patchedPkgs = import (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/468a37e6ba01c45c91460580f345d48ecdb5a4db.tar.gz";
        # sha256 = "sha256:057qsz43gy84myk4zc8806rd7nj4dkldfpn7wq6mflqa4bihvdka"; ??? BREAKS Mdevctl WHY OMFG!!
        sha256 = "sha256:11ri51840scvy9531rbz32241l7l81sa830s90wpzvv86v276aqs";
    }) {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    #inputs.nixos-nvidia-vgpu.nixosModules.nvidia-vgpu
    inputs.vgpu4nixos.nixosModules.host
    inputs.fastapi-dls-nixos.nixosModules.default
  ];
  
  options.mySystemHyruleCastle.vgpu = {
    enable = lib.mkEnableOption "NvidiaVgpuSharing";
  };

  config = lib.mkIf cfg.enable {

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
            name = "NVIDIA-Linux-x86_64-550.90.05-vgpu-kvm.run";
            #url = "http://downloads.protoducer.com/vGPU/17.3/Host_Drivers/NVIDIA-Linux-x86_64-550.90.05-vgpu-kvm.run";
            sha256 = "sha256-vBsxP1/SlXLQEXx70j/g8Vg/d6rGLaTyxsQQ19+1yp0=";
          };
        };
      };
    };

    programs.mdevctl = {
      enable = true;
    };

  };
}
