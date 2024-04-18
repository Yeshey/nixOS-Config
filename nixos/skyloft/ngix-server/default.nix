{ config, pkgs, user, location, lib, ... }:

let
  port = 7843; # 7843
  # Access with (ssh -L 9092:localhost:7843 -t yeshey@143.47.53.175 "sleep 90" &) && xdg-open http://localhost:9092
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
        root = ./src; 
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
