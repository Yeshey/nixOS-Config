{ inputs, ... }:
{
  flake.modules.nixos.open-webui =
    { pkgs, config, lib, ... }:
    let
      port = 11111;
      searxPort = 5564;
      litellmPort = 4000; # must match modules/services/hosting/litellm [N]/litellm.nix
    in
    {
      imports = [
        inputs.self.modules.nixos.ollama
        inputs.self.modules.nixos.litellm
      ];

      sops.secrets."nvidia_nim_api_key" = { };
      sops.secrets."openrouter" = { };
      sops.secrets."opencode_key" = { };
      sops.secrets."groq_key" = { };
      sops.secrets."vercel_key" = { };

      sops.templates."open-webui.env".content = ''
        OPENAI_API_KEYS=${config.sops.placeholder."litellm_master_key"};${config.sops.placeholder."nvidia_nim_api_key"};${config.sops.placeholder."openrouter"};${config.sops.placeholder."opencode_key"};${config.sops.placeholder."groq_key"};${config.sops.placeholder."vercel_key"}
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
          WEB_SEARCH_ENGINE = "exa";
          WEB_SEARCH_RESULT_COUNT = "5";
          WEB_SEARCH_CONCURRENT_REQUESTS = "3";
          ENABLE_PERSISTENT_CONFIG = "false";
          ENABLE_FOLLOW_UP_GENERATION = "false";
          ENABLE_TAGS_GENERATION = "false";
          ENABLE_TITLE_GENERATION = "false";
          OLLAMA_API_BASE_URL = "http://localhost:11434";

          OPENAI_API_BASE_URLS = "http://localhost:${toString litellmPort}/v1;https://integrate.api.nvidia.com/v1;https://openrouter.ai/api/v1;https://opencode.ai/zen/v1;https://api.groq.com/openai/v1;https://ai-gateway.vercel.sh/v1";
          # Map each endpoint index to its specific prefix
          OPENAI_API_CONFIGS = ''{"0": {"prefix_id": "googleAPI/"}, "1": {"prefix_id": "nvidiaAPI/"}, "2": {"prefix_id": "openrouterAPI/"}, "3": {"prefix_id": "opencodeAPI/"}, "4": {"prefix_id": "groqAPI/"}, "5": {"prefix_id": "vercelAPI/"}}'';

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