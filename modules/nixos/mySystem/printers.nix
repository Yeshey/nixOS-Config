{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.printers;
in
{
  options.mySystem.printers = {
    enable = lib.mkEnableOption "printers";
  };

  config = lib.mkIf cfg.enable {
    # Enable CUPS to print documents.
    services.printing.enable = true; # TODO check if it works with your printer
    environment = {
      systemPackages = with pkgs; [
        xsane
      ];
    };

  };
  
}
