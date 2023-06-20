{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
  imports = [
    # (import ./configFiles/nextcloud.nix)
    (import ./configFiles/minecraft.nix)
    (import ./hardware-configuration.nix)
  ];
  
  time.timeZone = "Europe/Berlin";

  # swap in btrfs:
  # ...

  nixpkgs.config = {
  	allowUnsupportedSystem = true;
  };

  #     ___            __ 
  #    / _ )___  ___  / /_
  #   / _  / _ \/ _ \/ __/
  #  /____/\___/\___/\__/  

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    
  ];

  #    ____             _               ____      ___                                 
  #   / __/__ _____  __(_)______ ___   / __/___  / _ \_______  ___ ________ ___ _  ___
  #  _\ \/ -_) __/ |/ / / __/ -_|_-<   > _/_ _/ / ___/ __/ _ \/ _ `/ __/ _ `/  ' \(_-<
  # /___/\__/_/  |___/_/\__/\__/___/  |_____/  /_/  /_/  \___/\_, /_/  \_,_/_/_/_/___/
  #                                                          /___/                                                               

  services.nginx.enable = true;
  services.nginx.virtualHosts."130.61.219.132" = {
      #addSSL = true;
      #enableACME = true;
      root = builtins.toFile "index.html" ''
<!DOCTYPE html>
<html>
    <head>
        <title>Example</title>
    </head>
    <body>
        <p>This is an example of a simple HTML page with one paragraph.</p>
    </body>
</html>
          '';
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "yesheysangpo@gmail.com";
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];

/*
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    virtualHosts."130.61.219.132" = {
      enableACME = true;
      locations."/".proxyPass = "http://localhost:8080";
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "yesheysangpo@gmail.com";
  }; */

}
