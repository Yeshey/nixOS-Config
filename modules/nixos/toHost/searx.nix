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
  };

  config = lib.mkIf cfg.enable {

    services.searx = {
      enable = true;
      settings = {
        server = {
          port = port;
          bind_address = "0.0.0.0";
          secret_key = "secret key";
        };
        search = {
          formats = [ "html" "json" ]; # to be able to be used in ollama 
        };
      };
    };

    environment.systemPackages =
      with pkgs;
      let
        searxWeb = makeDesktopItem {
          name = "Searx";
          desktopName = "Searx";
          genericName = "Searx";
          exec = ''xdg-open "http://localhost:${toString port}#"'';
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
