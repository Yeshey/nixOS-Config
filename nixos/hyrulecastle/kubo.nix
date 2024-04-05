{ config, pkgs, user, location, dataStoragePath, lib, ... }:

let
  
in
{

  # Check this to understand why added files with ipfs add don't show up in the webui: https://github.com/ipfs/ipfs-webui/issues/897
  services.kubo = let
    ipfsConfig = {  
      API = {
        HTTPHeaders = {
          "Access-Control-Allow-Origin" = [ "http://localhost:5001" "http://127.0.0.1:5001" "http://0.0.0.0:5001" "https://webui.ipfs.io" ];
          "Access-Control-Allow-Methods" = [ "PUT" "POST" ];
        };
      };
      Addresses = { # https://gist.github.com/schollz/b9bdddd83d9a83978afede443136c1cc
        Gateway = "/ip4/127.0.0.1/tcp/8080";
        API = "/ip4/127.0.0.1/tcp/5001";
      };
    };
    # With this you should be able to use the webui and see your deamon running in <one_of_the_Access-Control-Allow-Origin_urls>/webui, for example: http://0.0.0.0:5001/webui
  in {
    enable = true;
    settings = ipfsConfig; 
    #user = "yeshey";
    #group = "users";
    enableGC = true;
  };

}

