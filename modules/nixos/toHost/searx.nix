{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.searx;
  port = 8888;
in
{
  options.toHost.searx = {
    enable = (lib.mkEnableOption "searx");
    bind_address = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "the address where connecting to searx";
    };
  };

  config = lib.mkIf cfg.enable {

    services.searx = {
      enable = true;
      settings = {
        server = {
          port = port;
          bind_address = cfg.bind_address;
          secret_key = "secret key";
        };
        search = {
          formats = [ "html" "json" ]; # to be able to be used in ollama 
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ port ];

    environment.systemPackages =
      with pkgs;
      let
        searxWeb = makeDesktopItem {
          name = "Searx";
          desktopName = "Searx";
          genericName = "Searx";
          exec = ''xdg-open "http://${cfg.bind_address}:${toString port}#"'';
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
        xdg-utils
        searxWeb
      ];
  };
}
