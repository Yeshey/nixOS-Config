{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mySystemHyruleCastle.vgpuSpecialisation;

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
  
  options.mySystemHyruleCastle.vgpuSpecialisation = {
    enable = lib.mkEnableOption "NvidiaVgpuSharing specialisation";
  };

  config = lib.mkIf cfg.enable {
    specialisation.vgpuNixOS.configuration = {

      environment.etc."specialisation".text = "vgpuNixOS";

      environment.systemPackages = let
        # Looking glass B6 version in nixpkgs: 
        #myLookingGlassPkgs = import (builtins.fetchTarball {
        #    url = "https://github.com/NixOS/nixpkgs/archive/394571358ce82dff7411395829aa6a3aad45b907.tar.gz";
        #    sha256 = "sha256:1yrqrpmrdzbzcwb7kv9m6gbzjk68ljs098fv246brq6mc3s4v5qk";
        #}) { inherit system; };
        #looking-glass-client-B7-rc1 = myLookingGlassPkgs.looking-glass-client;
      in [
        # looking-glass-client-B7-rc1
        pkgs.looking-glass-client # for my windows 10 machine I want B7-rc1
        # for mdevctl you might need to create these folders if it gives error when running:
        # /usr/lib/mdevctl/scripts.d/callouts
        # /usr/lib/mdevctl/scripts.d/notifiers
        pkgs.mdevctl
      ];

      hardware.nvidia = {
        open = lib.mkForce false; # my GPU is listed under compatible GPUs: https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      };

      services.fastapi-dls = {
        enable = true;
        # All possible options are listed here:
        # https://git.collinwebdesigns.de/oscar.krause/fastapi-dls#configuration
        debug = true;                # DEBUG
        listen.ip = "0.0.0.0";      # DLS_URL localhost didn't work for me
      };

      boot.extraModprobeConfig = 
        ''
        options nvidia vup_sunlock=1 vup_swrlwar=1 vup_qmode=1
        ''; # (for driver 535) bypasses `error: vmiop_log: NVOS status 0x1` in nvidia-vgpu-mgr.service when starting VM
      # environment.etc."nvidia-vgpu-xxxxx/vgpuConfig.xml".source = config.hardware.nvidia.package + /vgpuConfig.xml;
      boot.kernelModules = [ "nvidia-vgpu-vfio" ];

      boot.kernelPackages = pkgs.linuxPackages_6_1; # needed, 6.1 is LTS

      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vgpu_16_5; # vgpu_17_3 vgpu_16_5

      hardware.nvidia.vgpu.patcher.enable = true;
      # hardware.nvidia.vgpu.patcher.options.remapP40ProfilesToV100D = true; # for 17_x
      # hardware.nvidia.vgpu.patcher.options.doNotForceGPLLicense = true; # This breaks :'D
      
      # hardware.nvidia.vgpu.driverSource.name = "NVIDIA-GRID-Linux-KVM-550.163.02-550.163.01-553.74.zip";

      #hardware.nvidia.vgpu.driverSource.name = "NVIDIA-GRID-Linux-KVM-550.90.05-550.90.07-552.74.zip"; # 17_3
      #hardware.nvidia.vgpu.driverSource.url = "https://drive.usercontent.google.com/download?id=12m0G2_8osDbouJtFnCAKKBzbxaMURDD5&confirm=xxx"; # 17_3 zip # looking glass wasnt working?
      
      # hardware.nvidia.vgpu.driverSource.name = "NVIDIA-GRID-Linux-KVM-580.65.05-580.65.06-580.88.zip"; # 16_5
      # hardware.nvidia.vgpu.driverSource.url = "https://drive.usercontent.google.com/download?id=1iVXS0uzQFzjbJSIM_XV2FKRMBIGnssJ6&confirm=xxx"; # 16_5 zip

      hardware.nvidia.vgpu.driverSource.name = "NVIDIA-GRID-Linux-KVM-535.161.05-535.161.08-538.46.zip"; # 16_5
      hardware.nvidia.vgpu.driverSource.url = "https://drive.usercontent.google.com/download?id=1iVXS0uzQFzjbJSIM_XV2FKRMBIGnssJ6&confirm=xxx"; # 16_5 zip

      # hardware.nvidia.vgpu.driverSource.name = "NVIDIA-GRID-Linux-KVM-550.90.05-550.90.07-552.74.zip"; # 17_3

      services.samba-wsdd.enable = true;
      networking.firewall.allowedTCPPorts = [
        5357 # wsdd
      ];
      networking.firewall.allowedUDPPorts = [
        3702 # wsdd
      ];
      services.samba = {
        enable = true;
        settings = {
          global = {
            "workgroup" = "WORKGROUP";
            "server string" = "smbnix";
            "netbios name" = "smbnix";
            "security" = "user";
            "guest account" = "nobody";
            "map to guest" = "bad user";
          };
          hdd-ntfs = {
            path = "/mnt/hdd-ntfs";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            "create mask" = "0644";
            "directory mask" = "0755";
          };
          DataDisk = {
            path = "/mnt/DataDisk";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            "create mask" = "0644";
            "directory mask" = "0755";
          };
        };
      };
      networking.firewall.allowPing = true;
      services.samba.openFirewall = true;

   };
  };
}