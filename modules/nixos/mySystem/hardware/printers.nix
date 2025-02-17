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
      drivers = with pkgs; [
        #xerox-generic-driver

        utsushi # XP-3100
        utsushi-networkscan # XP-3100?
      ];
    };
    environment = {
      systemPackages = with pkgs; [ xsane ];
    };

    # Madeira printer doesnt work:
    # services.printing.drivers = [ pkgs.dcp165c ];
    # extraGroups = [ "lp" ]; ?
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
