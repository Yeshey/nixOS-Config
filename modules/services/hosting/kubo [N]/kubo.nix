{ ... }:
{
  flake.modules.nixos.kubo =
    { pkgs, ... }:
    let
      port = 5001;
    in
    {
      # Check this to understand why added files with ipfs add don't show up in the webui:
      # https://github.com/ipfs/ipfs-webui/issues/897
      services.kubo = {
        enable = true;
        enableGC = true;
        settings = {
          API.HTTPHeaders = {
            "Access-Control-Allow-Origin" = [
              "*"
              "http://10.8.0.1:${toString port}"
              "http://localhost:${toString port}"
              "http://127.0.0.1:${toString port}"
              "http://0.0.0.0:${toString port}"
              "https://webui.ipfs.io"
            ];
            "Access-Control-Allow-Methods" = [ "PUT" "POST" "GET" ];
          };
          Addresses = {
            API     = "/ip4/0.0.0.0/tcp/${toString port}";
            Gateway = "/ip4/0.0.0.0/tcp/8080";
          };
          Experimental.Libp2pStreamMounting = true;
        };
      };

      # Access webui at http://0.0.0.0:8080/webui
      networking.firewall = {
        allowedTCPPorts = [ 8080 4001 port ];
        allowedUDPPorts = [ 4001 ];
      };

      environment.systemPackages =
        let
          kuboDesktopItem = pkgs.makeDesktopItem {
            name = "Kubo IPFS";
            desktopName = "Kubo IPFS";
            genericName = "Kubo IPFS";
            exec = ''xdg-open "http://localhost:${toString port}/webui"'';
            icon = "firefox";
            categories = [ "GTK" "X-WebApps" ];
            mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
          };
        in
        [ kuboDesktopItem ];
    };
}