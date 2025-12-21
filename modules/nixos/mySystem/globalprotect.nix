{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.globalprotect;
in
{
  options.mySystem.globalprotect = {
    enable = lib.mkEnableOption "globalprotect";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {  

    environment.systemPackages = [ 
      # inputs.globalprotect-openconnect.packages.${pkgs.system}.default
      pkgs.gpclient

      (pkgs.makeDesktopItem {
        name = "gpclient-iscte";
        desktopName = "GlobalProtect ISCTE-IUL";
        genericName = "GlobalProtect VPN Client";
        comment = "Connect to ISCTE-IUL VPN";
        exec = "sudo -E gpclient --fix-openssl connect --browser default vpn.iscte-iul.pt %u";
        icon = "network-vpn";
        categories = [ "Network" "Dialup" ];
        keywords = [
          "GlobalProtect"
          "Openconnect"
          "SAML"
          "connection"
          "VPN"
        ];
        mimeTypes = ["x-scheme-handler/globalprotectcallback"];
        terminal = true;
      })
    ];

  };
}

# Launch GlobalProtect on App launcher
# go into vpn.iscte-iul.pt
# Fill your credentials
# activate with: 
# sudo -E gpclient --fix-openssl connect --browser default vpn.iscte-iul.pt