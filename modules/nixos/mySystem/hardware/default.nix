{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.hardware;
in
{
  imports = [
    ./bluetooth.nix
    ./sound.nix
    ./printers.nix
    ./nvidia.nix
    ./thermald.nix
    ./lvm.nix
  ];

  options.mySystem.hardware = {
    enable = lib.mkEnableOption "hardware";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    mySystem.hardware.bluetooth.enable = lib.mkOverride 1010 true;
    mySystem.hardware.printers.enable = lib.mkOverride 1010 true;
    mySystem.hardware.sound.enable = lib.mkOverride 1010 true;
    mySystem.hardware.thermald.enable = lib.mkOverride 1010 true;
    mySystem.hardware.nvidia.enable = lib.mkOverride 1010 false;
    mySystem.hardware.lvm.enable = lib.mkOverride 1010 false;
  };
}
