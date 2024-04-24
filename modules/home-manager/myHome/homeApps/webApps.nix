{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  c = config.myHome.colorScheme.theme.palette;
  cfg = config.myHome.homeApps.webApps;
in
{
  options.myHome.homeApps.webApps = with lib; {
    enable = mkEnableOption "webApps";
  };

  config = lib.mkIf cfg.enable {

    # makeDesktopItem https://discourse.nixos.org/t/proper-icon-when-using-makedesktopitem/32026
    # Syncthing desktop shortcut
    home.packages = with pkgs; 
      let
        syncthingWeb = pkgs.makeDesktopItem {
          name = "MS WhiteBoard";
          desktopName = "MS WhiteBoard";
          genericName = "MS WhiteBoard Web App";
          exec = ''xdg-open "https://whiteboard.office.com"'';
          icon = "firefox";
          categories = [ "GTK" "X-WebApps" ];
          mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
        };
      in
      [
        xdg-utils
        syncthingWeb
      ];

  };
}