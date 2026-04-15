{ inputs, ... }:
{
  flake.modules.nixos.nvidia = { config, lib, pkgs, ... }:
    let
      # Logic remains the same, but we point to config values instead of hardcoded strings
      cfg = config.hardware.nvidia.prime.busIds;
      
      nvitopDesktop = pkgs.makeDesktopItem {
        name = "nvitop";
        desktopName = "NVITOP";
        comment = "NVIDIA GPU monitoring (nvitop)";
        exec = "nvitop";
        icon = "org.gnome.SystemMonitor";
        categories = [ "System" "Monitor" "ConsoleOnly" ];
        terminal = true;
      };
    in
    {
      # 1. Define the interface (What this module needs from the host)
      options.hardware.nvidia.prime.busIds = {
        intel = lib.mkOption {
          type = lib.types.str;
          description = "Bus ID of the Intel GPU (e.g., PCI:0:2:0)";
        };
        nvidia = lib.mkOption {
          type = lib.types.str;
          description = "Bus ID of the NVIDIA GPU (e.g., PCI:1:0:0)";
        };
      };

      # 2. Define the implementation
      config = {
        hardware.nvidia-container-toolkit.enable = true;
        services.xserver.videoDrivers = [ "nvidia" ];
        
        environment.systemPackages = with pkgs; [
          cudaPackages.cudatoolkit
          nvitop
          nvitopDesktop
        ];

        hardware.nvidia = {
          open = true;
          modesetting.enable = true;
          powerManagement.enable = true;
          powerManagement.finegrained = false;
          prime = {
            offload.enable = true;
            intelBusId = cfg.intel;
            nvidiaBusId = cfg.nvidia;
          };
        };
      };
    };
}