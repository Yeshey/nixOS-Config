{ inputs, ... }:
{
  flake.modules.nixos.ollama =
    { pkgs, config, lib, ... }:
    let
      port = 11111;
      searxPort = 5564;
      litellmPort  = 4000;
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
          RAG_WEB_SEARCH_RESULT_COUNT = "5";
          RAG_WEB_SEARCH_ENGINE = "searxng";
          SEARXNG_QUERY_URL = "http://localhost:${toString searxPort}/search?q=<query>&format=json";
          OLLAMA_API_BASE_URL = "http://localhost:11434";
          WEBUI_AUTH = "False";
        };
      };

      sops.secrets."litellm_env" = {};
      systemd.services.litellm.serviceConfig.EnvironmentFile = config.sops.secrets."litellm_env".path;
      services.litellm = {
        enable = true;
        host = "0.0.0.0";
        port = litellmPort;
        openFirewall = true;
        
        settings = {
          model_list = [
            {
              # The balanced 3.6 model you requested
              model_name = "gemini-3.6-flash";
              litellm_params = {
                model = "gemini/gemini-3.6-flash";
                api_key = "os.environ/GEMINI_API_KEY";
              };
            }
            {
              # The latest fast model
              model_name = "gemini-3.8-flash";
              litellm_params = {
                model = "gemini/gemini-3.8-flash";
                api_key = "os.environ/GEMINI_API_KEY";
              };
            }
            {
              # Highly cost-efficient and fastest option
              model_name = "gemini-3.5-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.5-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
              };
            }
            {
              # Best for complex reasoning and coding
              model_name = "gemini-3.1-pro-preview";
              litellm_params = {
                model = "gemini/gemini-3.1-pro-preview";
                api_key = "os.environ/GEMINI_API_KEY";
              };
            }
            {
              # The older stable Pro model
              model_name = "gemini-2.5-pro";
              litellm_params = {
                model = "gemini/gemini-2.5-pro";
                api_key = "os.environ/GEMINI_API_KEY";
              };
            }
          ];
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
            icon = pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/open-webui/open-webui/main/static/favicon.png";
              sha256 = "sha256-Vpij45UT57YwTslsMJNzqzrw9w/nlCk0Yd45WpTeqmU=";
            };
            categories = [ "GTK" "X-WebApps" ];
            mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
          };
        in
        [ pkgs.xdg-utils open-webui-desktop pkgs.oterm ];
    };
}