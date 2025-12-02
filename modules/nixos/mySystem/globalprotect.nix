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
        comment = "Connect to ISCTE-IUL VPN";
        exec = "sudo -E gpclient --fix-openssl connect --browser default vpn.iscte-iul.pt";
        icon = "network-vpn";
        categories = [ "Network" ];
        terminal = true;  # This opens in your default terminal
      })
    ];

  };
}

# Launch GlobalProtect on App launcher
# go into vpn.iscte-iul.pt
# Fill your credentials
# activate with: 
# sudo -E gpclient --fix-openssl connect --browser default vpn.iscte-iul.pt