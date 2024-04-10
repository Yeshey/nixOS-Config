{ config, pkgs, user, location, lib, ... }:

let # TODO ugly!
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
{
    imports = [
        # ...
    ];

  # NVIDIA
  # Allow unfree packages
  nixpkgs.config = {
    cudaSupport = true; # for blender (nvidia)
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "nvidia-x11"
    "nvidia-settings"
  ];
  # NVIDIA drivers 
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  # Comment this to use only the nvidia Grpahics card, or when you're not passing the nvidia card inside?
  hardware.nvidia = {
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    prime = {
      sync.enable = true; # https://github.com/NixOS/nixpkgs/issues/199024#issuecomment-1300650034
      #offload.enable = true;
      intelBusId = "PCI:0:1:0";
      nvidiaBusId = "PCI:8:0:0";
    };
  };
  environment.systemPackages = with pkgs; [
    # NVIDIA
    cudaPackages.cudatoolkit # for blender (nvidia)
    nvidia-offload

    # Games
    steam
  ];


}
