{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  c = config.myHome.colorScheme.theme.palette;
  cfg = config.myHome.homeApps.libreoffice;
in
{
  options.myHome.homeApps.libreoffice = with lib; {
    enable = mkEnableOption "libreoffice";
  };

  config = lib.mkIf cfg.enable {

    home = { # Specific packages
      packages = with pkgs; [
        # Libreoffice
        libreoffice
        corefonts # fonts
        vistafonts # fonts
        hunspell
        hunspellDicts.uk_UA
      ];
    };
    
  };
}