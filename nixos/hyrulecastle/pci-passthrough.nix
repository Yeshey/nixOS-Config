# https://gist.github.com/WhittlesJr/a6de35b995e8c14b9093c55ba41b697c

{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.mySystemHyruleCastle.pciPassthrough;
in
{
  ###### interface
  options.mySystemHyruleCastle.pciPassthrough = {
    enable = mkEnableOption "PCI Passthrough";

    cpuType = mkOption {
      description = "One of `intel` or `amd`";
      default = "intel";
      type = types.str;
    };

    pciIDs = mkOption {
      description = "Comma-separated list of PCI IDs to pass-through";
      type = types.str;
    };

    libvirtUsers = mkOption {
      description = "Extra users to add to libvirtd (root is already included)";
      type = types.listOf types.str;
      default = [ ];
    };
  };

  ###### implementation
  config = (
    mkIf cfg.enable {

      assertions = [
        {
          assertion = !(config.mySystemHyruleCastle.pciPassthrough.enable && config.mySystemHyruleCastle.vgpu.enable);
          message = "You cannot use both pciPassthrough and nvidiaVgpuSharing methods to share GPU power, pick one";
        }
      ];

      boot.kernelParams = [
        "${cfg.cpuType}_iommu=on"
        "kvm.ignore_msrs=1"
        "iommu=pt"
      ];

      # These modules are required for PCI passthrough, and must come before early modesetting stuff
      boot.kernelModules = [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
        "vfio_virqfd"
      ];

      boot.extraModprobeConfig = "options vfio-pci ids=${cfg.pciIDs}";

      environment.systemPackages = with pkgs; [
        virt-manager
        qemu
        OVMF
        pciutils
      ];

      # ===== My added conf =====
      boot.blacklistedKernelModules = [
        "nvidia"
        "nouveau"
      ];
      # also need prime.offload for it to work
      hardware.nvidia.prime.offload.enable = lib.mkForce true;
      hardware.nvidia.prime.sync.enable = lib.mkForce false;
      # ===== My added conf =====

      virtualisation.libvirtd.enable = true;
      virtualisation.libvirtd.qemu.package = pkgs.qemu_kvm;

      users.groups.libvirtd.members = [ "root" ] ++ cfg.libvirtUsers;

      virtualisation.libvirtd.qemu.verbatimConfig = ''
        nvram = [
        "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd"
        ]
      '';
    }
  );
}
