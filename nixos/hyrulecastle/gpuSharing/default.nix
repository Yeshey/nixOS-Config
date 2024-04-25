{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.mySystem.gpuSharing;
in
{
  imports = [
    ./pci-passthrough.nix
    #inputs.nixos-nvidia-vgpu
  ];
  
  options.mySystem.gpuSharing = {
    pciPassthrough.enable = mkEnableOption "PCI Passthrough";

    pciPassthrough.cpuType = mkOption {
      description = "One of `intel` or `amd`";
      default = "intel";
      type = types.str;
    };

    pciPassthrough.pciIDs = mkOption {
      description = "Comma-separated list of PCI IDs to pass-through";
      type = types.str;
    };

    pciPassthrough.libvirtUsers = mkOption {
      description = "Extra users to add to libvirtd (root is already included)";
      type = types.listOf types.str;
      default = [ ];
    };

    nvidiaVgpuSharing.enable = mkEnableOption "NvidiaVgpuSharing";
  };

  config = {

    assertions = [
      {
        assertion = !(cfg.pciPassthrough.enable && cfg.nvidiaVgpuSharing.enable);
        message = "You cannot use both pciPassthrough and nvidiaVgpuSharing methods to share GPU power, pick one";
      }
    ];

    # https://gist.github.com/WhittlesJr/a6de35b995e8c14b9093c55ba41b697c
    # Enable the module with pciIDs = ""; and then run one of these commands to find the pciIDs:
    # for d in /sys/kernel/iommu_groups/*/devices/*; do n="${d#*/iommu_groups/*}"; n="${n%%/*}"; printf 'IOMMU Group %s \t' "$n"; lspci -nns "${d##*/}"; done | sort -h -k 3 | grep --color -e ".*NVIDIA.*" -e "^"
    # nix-shell -p pciutils --command "sudo lspci -nnk" | grep --color -e ".*NVIDIA.*" -e "^"
    pciPassthrough = {
      # you will also need to set hardware.nvidia.prime.offload.enable = true for this GPU passthrough to work  (or the sync method?)
      enable = cfg.pciPassthrough.enable;
      cpuType = cfg.pciPassthrough.cpuType;
      #pciIDs = "";
      pciIDs = cfg.pciPassthrough.pciIDs; # "10de:1f11,10de:10f9,8086:1901,10de:1ada" ; # Nvidia VGA, Nvidia Audia,... ;
      libvirtUsers = cfg.pciPassthrough.libvirtUsers;
    };

    boot.kernelPackages = lib.mkIf cfg.nvidiaVgpuSharing.enable pkgs.linuxPackages_5_15; # needed for this linuxPackages_5_19
    hardware.nvidia = lib.mkIf cfg.nvidiaVgpuSharing.enable {
      vgpu = {
        enable = true; # Install NVIDIA KVM vGPU + GRID driver
        unlock.enable = true; # Unlock vGPU functionality on consumer cards using DualCoder/vgpu_unlock project.
        fastapi-dls = {
          enable = true;
          local_ipv4 = "localhost"; #"192.168.1.109";
          timezone = "Europe/Lisbon";
          #docker-directory = /mnt/dockers;
        };
      };
    };

  };
}
