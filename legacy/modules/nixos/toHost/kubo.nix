{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.kubo;
in
{
  options.toHost.kubo = {
    enable = (lib.mkEnableOption "kubo");
    port = lib.mkOption {
      type = lib.types.port;
      default = 5001;
      description = "Remote port number to use";
    };
  };

  config = lib.mkIf cfg.enable {

    # # Check this to understand why added files with ipfs add don't show up in the webui: https://github.com/ipfs/ipfs-webui/issues/897
    services.kubo =
      let
        ipfsConfig = {
          API = {
            HTTPHeaders = {
              "Access-Control-Allow-Origin" = [
                "*" # should probably remove later as well
                "http://10.8.0.1:${toString cfg.port}" # For the VPN
                "http://localhost:${toString cfg.port}"
                "http://127.0.0.1:${toString cfg.port}"
                "http://0.0.0.0:${toString cfg.port}"
                "https://webui.ipfs.io"
              ];
              "Access-Control-Allow-Methods" = [
                "PUT"
                "POST"
                "GET"
              ];
            };
          };
          Addresses = {
            # https://gist.github.com/schollz/b9bdddd83d9a83978afede443136c1cc
            # Gateway = "/ip4/127.0.0.1/tcp/8080";
            # API = "/ip4/127.0.0.1/tcp/${toString cfg.port}";
            API     = "/ip4/0.0.0.0/tcp/${toString cfg.port}";    # listen on all interfaces
            Gateway = "/ip4/0.0.0.0/tcp/8080";                   # web gateway (webui) on all interfaces
            # You could also make it work ONLY on your VPN 10.8.0.1
          };
          Experimental = {
            Libp2pStreamMounting = true;
          };
        };
      in
      # With this you should be able to use the webui and see your deamon running in <one_of_the_Access-Control-Allow-Origin_urls>/webui, for example: http://0.0.0.0:8080/webui
      {
        enable = true;
        settings = ipfsConfig;
        #user = "yeshey";
        #group = "users";
        enableGC = true;
      };

    # makeDesktopItem https://discourse.nixos.org/t/proper-icon-when-using-makedesktopitem/32026
    # kubo desktop shortcut
    environment.systemPackages =
      with pkgs;
      let
        kuboDesktopItem = makeDesktopItem {
          name = "Kubo IPFS";
          desktopName = "Kubo IPFS";
          genericName = "Kubo IPFS";
          exec = ''xdg-open "http://localhost:${toString cfg.port}/webui"'';
          icon = "firefox";
          categories = [
            "GTK"
            "X-WebApps"
          ];
          mimeTypes = [
            "text/html"
            "text/xml"
            "application/xhtml_xml"
          ];
        };
      in
      [
        kuboDesktopItem
      ];

    networking.firewall = {
      # IPFS Gateway (HTTP)
      allowedTCPPorts = [
        8080 # people can see my gateway
        4001 # discoverability
        cfg.port # should remove later, allows access to API
      ];

      # IPFS QUIC / UDP swarm
      allowedUDPPorts = [
        4001 # discoverability
      ];
    };

  };
}
