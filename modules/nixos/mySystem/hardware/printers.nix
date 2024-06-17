{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.hardware.printers;
in
{
  options.mySystem.hardware.printers = {
    enable = lib.mkEnableOption "printers";
  };

  config = lib.mkIf (config.mySystem.enable && config.mySystem.hardware.enable && cfg.enable) {
    # Enable CUPS to print documents.
    services.printing = {
      enable = true; # TODO check if it works with your printer
      #drivers = with pkgs; [
      #  xerox-generic-driver
      #];
    };
    environment = {
      systemPackages = with pkgs; [ xsane ];
    };
  };
}
