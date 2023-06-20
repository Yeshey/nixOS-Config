{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
  imports = [
    # ...
  ];
  
  # NextCloud
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud26;
    hostName = "localhost";
    config.adminpassFile = "${pkgs.writeText "adminpass" "test123"}";
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];

}
