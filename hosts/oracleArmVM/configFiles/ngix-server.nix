{ config, pkgs, user, location, lib, dataStoragePath, ... }:

let
  port = 7843;
in
{
    imports = [
        # ...
    ];

  services.nginx = {
    enable = true;
    virtualHosts."anything" = {
        #addSSL = true;
        #enableACME = true;
        root = ./ngix-server; 
        listen = [{port = port;  addr="0.0.0.0"; }]; #(https://discourse.nixos.org/t/nginx-multiple-different-ports-in-one-virtual-host/2988/6)
        #listen.port = 80;
    };
  }; 
  security.acme = {
    acceptTerms = true;
    defaults.email = "yesheysangpo@gmail.com";
  };
  networking.firewall.allowedTCPPorts = [ port ];

}