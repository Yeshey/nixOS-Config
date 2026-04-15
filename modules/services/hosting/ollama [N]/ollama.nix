{ inputs, ... }:
{
  flake.modules.nixos.ollama =
    { pkgs, lib, ... }:
    let
      port = 11111;
      searxPort = 5564;
    in
    {
      imports = with inputs.self.modules.nixos; [
        searx
      ];

      services.ollama = {
        package = pkgs.unstable.ollama;
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        environmentVariables = {
          OLLAMA_ORIGINES = "*";
        };
      };

      services.open-webui = {
        package = pkgs.open-webui;
        enable = true;
        openFirewall = true;
        port = port;
        host = "0.0.0.0";
        environment = {
          GLOBAL_LOG_LEVEL = "DEBUG";
          ENABLE_RAG_WEB_SEARCH = "True";
          RAG_WEB_SEARCH_RESULT_COUNT = "1";
          RAG_WEB_SEARCH_ENGINE = "searxng";
          SEARXNG_QUERY_URL = "http://localhost:${toString searxPort}/search?q=<query>";
          OLLAMA_API_BASE_URL = "http://localhost:11434";
          WEBUI_AUTH = "False";
        };
      };

      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port searxPort ];

      environment.systemPackages =
        let
          open-webui-desktop = pkgs.makeDesktopItem {
            name = "Ollama open WebUI";
            desktopName = "Ollama open WebUI";
            genericName = "Ollama open WebUI";
            exec = ''brave "http://localhost:${toString port}/?web-search=true"'';
            icon = "firefox";
            categories = [ "GTK" "X-WebApps" ];
            mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
          };
        in
        [ pkgs.xdg-utils open-webui-desktop pkgs.oterm ];
    };
}