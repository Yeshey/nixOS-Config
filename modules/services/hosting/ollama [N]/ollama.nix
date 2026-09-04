{ inputs, ... }:
{
  flake.modules.nixos.ollama =
    { pkgs, config, lib, ... }:
    let
      port = 11111;
      searxPort = 5564;
      litellmPort = 4000; # must match modules/services/hosting/litellm [N]/litellm.nix
    in
    {
      imports = [ inputs.self.modules.nixos.litellm ];

      services.ollama = {
        package = pkgs.unstable.ollama;
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        environmentVariables = {
          OLLAMA_ORIGINS = "*";
        };
      };

      sops.secrets."nvidia_nim_api_key" = { };
      sops.secrets."openrouter" = { };

      sops.templates."open-webui.env".content = ''
        OPENAI_API_KEYS=${config.sops.placeholder."litellm_master_key"};${config.sops.placeholder."nvidia_nim_api_key"};${config.sops.placeholder."openrouter"}
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
          ENABLE_FOLLOW_UP_GENERATION = "false";
          ENABLE_TITLE_GENERATION = "false";
          OLLAMA_API_BASE_URL = "http://localhost:11434";
          OPENAI_API_BASE_URLS = "http://localhost:${toString litellmPort}/v1;https://integrate.api.nvidia.com/v1;https://openrouter.ai/api/v1";
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