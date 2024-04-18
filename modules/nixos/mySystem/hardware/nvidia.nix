{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.hardware.nvidia;
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
{
  options.mySystem.hardware.nvidia = with lib; {
    enable = mkEnableOption "nvidia";
    intelBusId = mkOption {
      type = types.str;
      example = "PCI:0:2:0";
    };
    nvidiaBusId = mkOption {
      type = types.str;
      example = "PCI:1:0:0";
    };
  };

  config = lib.mkIf cfg.enable {

    # NVIDIA
    # Allow unfree packages
    nixpkgs.config = {
        cudaSupport = true; # for blender (nvidia)
    };
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
        "nvidia-x11"
        "nvidia-settings"
    ];
    environment.systemPackages = with pkgs; [
        # NVIDIA
        cudaPackages.cudatoolkit # for blender (nvidia)
        nvidia-offload
        # gwe?
    ];
    # NVIDIA drivers 
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.opengl.enable = true;

    # Comment this to use only the nvidia Grpahics card (discrete graphics option in BIOS instead of switchable graphics)
    hardware.nvidia = {
        #package = config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = true;
        # nvidiaPersistenced = true; # It ensures all GPUs stay awake even during headless mode.
        powerManagement.enable = true; # Experimental power management through systemd
        prime = {
        sync.enable = true; # gpu always # https://github.com/NixOS/nixpkgs/issues/199024#issuecomment-1300650034 # does not work with GPU passthrough
        #offload.enable = true; # gpu on demand # works with GPU passthrough
        intelBusId = cfg.intelBusId; # "PCI:0:2:0";
        nvidiaBusId = cfg.nvidiaBusId; #"PCI:1:0:0";
        };
    };
    # required for external monitor usage on nvidia offload (or not?)
    specialisation = {
        external-display.configuration = {
        system.nixos.tags = [ "external-display" ];
        hardware.nvidia.prime.offload.enable = lib.mkForce false;
        hardware.nvidia.powerManagement.enable = lib.mkForce false;
        };
    };

  };
}
