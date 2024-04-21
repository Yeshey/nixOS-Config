{ inputs, config, lib, pkgs, ... }:

let
  cfg = config.mySystem.hyprland;
in
{
  options.mySystem.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    # if nvidia
    boot.kernelParams = lib.mkIf config.mySystem.hardware.nvidia.enable [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    hardware.nvidia.powerManagement.enable = lib.mkIf config.mySystem.hardware.nvidia.enable true;
    # Making sure to use the proprietary drivers until the issue above is fixed upstream
    hardware.nvidia.open = lib.mkIf config.mySystem.hardware.nvidia.enable false;
  };
}
