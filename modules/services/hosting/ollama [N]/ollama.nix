{ inputs, ... }:
{
  flake.modules.nixos.ollama =
    { pkgs, config, lib, ... }:
    let
      port = 11111;
      searxPort = 5564;
      litellmPort = 4000;
    in
    {
      services.ollama = {
        package = pkgs.unstable.ollama;
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        environmentVariables = {
          OLLAMA_ORIGINS = "*";
        };
      };

      # single source of truth for each secret — each defined exactly once
      sops.secrets."gemini_api_key" = {};
      sops.secrets."nvidia_nim_api_key" = {};
      sops.secrets."litellm_master_key" = {};

      # composed env files — reference the secrets above via placeholder, never duplicate values
      sops.templates."litellm.env".content = ''
        GEMINI_API_KEY=${config.sops.placeholder."gemini_api_key"}
        LITELLM_MASTER_KEY=${config.sops.placeholder."litellm_master_key"}
      '';

      sops.templates."open-webui.env".content = ''
        OPENAI_API_KEYS=${config.sops.placeholder."litellm_master_key"};${config.sops.placeholder."nvidia_nim_api_key"}
      '';

      systemd.services.open-webui.serviceConfig.EnvironmentFile = [
        config.sops.secrets."searx_env".path
        config.sops.templates."open-webui.env".path
      ];
      sops.secrets."searx_env" = {
        restartUnits = [ "open-webui.service" ];
      };

      services.open-webui = {
        package = pkgs.open-webui;
        enable = true;
        openFirewall = true;
        port = port;
        host = "0.0.0.0";
        environment = {
          GLOBAL_LOG_LEVEL = "DEBUG";
          ENABLE_WEB_SEARCH = "true";
          WEB_SEARCH_ENGINE = "tavily";
          WEB_SEARCH_RESULT_COUNT = "5";
          WEB_SEARCH_CONCURRENT_REQUESTS = "3";
          ENABLE_PERSISTENT_CONFIG = "false";
          OLLAMA_API_BASE_URL = "http://localhost:11434";
          OPENAI_API_BASE_URLS = "http://localhost:${toString litellmPort}/v1;https://integrate.api.nvidia.com/v1";
          WEBUI_AUTH = "False";
        };
      };

      systemd.services.litellm.serviceConfig.EnvironmentFile = config.sops.templates."litellm.env".path;
      services.litellm = {
        enable = true;
        host = "0.0.0.0";
        port = litellmPort;
        openFirewall = true;

        settings = {
          model_list = [
            {
              model_name = "gemini-3.6-flash";
              litellm_params = {
                model = "gemini/gemini-3.6-flash";
                api_key = "os.environ/GEMINI_API_KEY";
              };
            }
            {
              model_name = "gemini-3.8-flash";
              litellm_params = {
                model = "gemini/gemini-3.8-flash";
                api_key = "os.environ/GEMINI_API_KEY";
              };
            }
            {
              model_name = "gemini-3.5-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.5-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
              };
            }
            {
              model_name = "gemini-3.1-pro-preview";
              litellm_params = {
                model = "gemini/gemini-3.1-pro-preview";
                api_key = "os.environ/GEMINI_API_KEY";
              };
            }
            {
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