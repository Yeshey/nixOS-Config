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
  ];

  options.mySystem.hardware = {
    enable = lib.mkEnableOption "hardware";
  };

  config = lib.mkIf cfg.enable {
    mySystem.hardware.bluetooth.enable = lib.mkDefault true;
    mySystem.hardware.printers.enable = lib.mkDefault true;
    mySystem.hardware.sound.enable = lib.mkDefault true;
    mySystem.hardware.nvidia.enable = lib.mkDefault true;
    mySystem.hardware.thermald.enable = lib.mkDefault true;
  };
}