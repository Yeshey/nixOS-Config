{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
    imports = [
        # ...
    ];

  # Doesn't work
  services.nginx = {
    enable = true;
    virtualHosts."130.61.219.132" = {
        #addSSL = true;
        #enableACME = true;
        root = ./ngix-server; 
    };
  }; 
  security.acme = {
    acceptTerms = true;
    defaults.email = "yesheysangpo@gmail.com";
  };
  networking.firewall.allowedTCPPorts = [ 80 ];

}
