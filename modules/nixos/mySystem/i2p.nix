{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.i2p;
in
{
  options.mySystem.i2p = with lib; {
    enable = mkEnableOption "i2p";
  };

  config = lib.mkIf cfg.enable {

    # http://127.0.0.1:7657/welcome
    services.i2p = {
      enable = true;
    };

    # TODO can't make general firefox profiles, the desktop file would be made like this tho:

    # makeDesktopItem https://discourse.nixos.org/t/proper-icon-when-using-makedesktopitem/32026
    /* environment.systemPackages = with pkgs; 
      let
        profile = ./i2p;
        i2ptest = makeDesktopItem {
          name = "i2ptest";
          desktopName = "i2ptest";
          genericName = "i2ptest";
          exec = ''firefox --name firefox %U --profile ${profile}'';
          icon = "firefox";
          categories = [ "Network" "WebBrowser" ];
          mimeTypes = [ "text/html" "text/xml" "application/xhtml+xml" "application/vnd.mozilla.xul+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
        };
      in
      [
        i2ptest
      ]; */
    
  };
}

