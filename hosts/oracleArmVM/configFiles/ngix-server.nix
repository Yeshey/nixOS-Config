{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
    imports = [
        # ...
    ];

  # Doesn't work
  services.nginx.enable = true;
  services.nginx.virtualHosts."130.61.219.132" = {
      #addSSL = true;
      #enableACME = true;
      root = ./ngix-server; 
      
      /*builtins.toFile "index.html" ''
<!DOCTYPE html>
<html>
    <head>
        <title>Example</title>
    </head>
    <body>
        <p>This is an example of a simple HTML page with one paragraph.</p>
    </body>
</html>
          ''; */
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "yesheysangpo@gmail.com";
  };
  networking.firewall.allowedTCPPorts = [ 80 ];

}
