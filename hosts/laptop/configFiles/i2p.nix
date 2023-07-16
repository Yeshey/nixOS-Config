{ config, pkgs, user, location, dataStoragePath, lib, ... }:

let
  
in
{

  # http://127.0.0.1:7657/welcome
  services.i2p = {
    enable = true;
    
    #upnp.enable = true;
  };

}

