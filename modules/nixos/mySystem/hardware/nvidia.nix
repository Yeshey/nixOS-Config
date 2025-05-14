{
  config,
  lib,
  pkgs,
  ...
}:

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
    GPUName = mkOption {
      type = types.str;
      default = "GeForce RTX 2060 Mobile";
      example = "GeForce RTX 2060 Mobile";
    };
  };

  config = lib.mkIf (config.mySystem.enable && config.mySystem.hardware.enable && cfg.enable) {

    system.activationScripts = {
    # do i need this shit for external monitors to work as well?
    # https://askubuntu.com/questions/986394/problem-with-second-monitors-resolution
    # maybe use services.xserver.deviceSection?
      monitors.text = ''
        echo "
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    BoardName      "${cfg.GPUName}"
    Option "IgnoreEDIDChecksum" "DFP-1"
EndSection
        " > "/etc/X11/xorg.conf"
      '';
    };

    # NVIDIA
    # Allow unfree packages
    nixpkgs.config = {
      cudaSupport = lib.mkOverride 1010 true; # for blender (nvidia)
    };
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (pkgs.lib.getName pkg) [
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
    hardware.graphics.enable = lib.mkOverride 1010 true;

    # Comment this to use only the nvidia Grpahics card (discrete graphics option in BIOS instead of switchable graphics)
    hardware.nvidia = {
      open = true;
      #package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = lib.mkOverride 1010 true;
      # nvidiaPersistenced = true; # It ensures all GPUs stay awake even during headless mode.
      powerManagement.enable = lib.mkOverride 1010 true; # Experimental power management through systemd
      prime = {
        # sync.enable = lib.mkOverride 1010 true; # gpu always # https://github.com/NixOS/nixpkgs/issues/199024#issuecomment-1300650034 # does not work with GPU passthrough
        offload.enable = true; # gpu on demand # works with GPU passthrough
        intelBusId = lib.mkOverride 1010 cfg.intelBusId; # "PCI:0:2:0";
        nvidiaBusId = lib.mkOverride 1010 cfg.nvidiaBusId; # "PCI:1:0:0";
      };
    };
    # required for external monitor usage on nvidia offload (or not?)
    /*
    specialisation = {
      external-display.configuration = {
        system.nixos.tags = [ "external-display" ];
        hardware.nvidia.prime.offload.enable = lib.mkForce false;
        hardware.nvidia.powerManagement.enable = lib.mkForce false;
      };
    }; */
    
    hardware.graphics.extraPackages = [
      pkgs.nvidia-vaapi-driver
    ];

    environment.variables = {
      NVD_BACKEND = "direct";
      LIBVA_DRIVER_NAME = "nvidia";

      MOZ_DISABLE_RDD_SANDBOX = "1"; # for firefox

      # wayland support
      # Required to run the correct GBM backend for nvidia GPUs on wayland
      GBM_BACKEND = "nvidia-drm";
      # Apparently, without this nouveau may attempt to be used instead
      # (despite it being blacklisted)
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # Hardware cursors are currently broken on wlroots
      WLR_NO_HARDWARE_CURSORS = "1";
    };

    # Firefox support
    programs.firefox.preferences = {
      "media.ffmpeg.vaapi.enabled" = true;
      "media.rdd-ffmpeg.enabled" = true;
      "media.av1.enabled" = false; # Won't work on the 2060
      "gfx.x11-egl.force-enabled" = true;
      "widget.dmabuf.force-enabled" = true;
    };
  };
}
