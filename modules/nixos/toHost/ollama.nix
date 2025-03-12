{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.ollama;
in
{
  options.toHost.ollama = {
    enable = lib.mkEnableOption "ollama";
    acceleration = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null; # Default is null
      description = "Acceleration type (e.g., 'cuda' or 'rocm'), or null to use the default.";
    };
  };

  config = lib.mkIf (cfg.enable)  {

    services.ollama = {
      package = pkgs.unstable.ollama;
      enable = true;
      openFirewall = true;
      acceleration = if cfg.acceleration == null then null else cfg.acceleration;
      #host = "localhost";
      host = "0.0.0.0";
    };
    # systemctl status open-webui
    services.open-webui = {
      package = pkgs.unstable.open-webui;
      enable = true;
      openFirewall = true;
      port = 11111;
      environment = {
        GLOBAL_LOG_LEVEL="DEBUG";
        # https://docs.openwebui.com/getting-started/env-configuration#web-search
        ENABLE_RAG_WEB_SEARCH = "True";
        
        RAG_WEB_SEARCH_RESULT_COUNT = "1";
        RAG_WEB_SEARCH_ENGINE = "searxng"; #"google_pse";
        SEARXNG_QUERY_URL = "http://localhost:8888/search?q=<query>";

        #RAG_WEB_SEARCH_RESULT_COUNT = "3";
        #RAG_WEB_SEARCH_ENGINE = "google_pse";
        #GOOGLE_PSE_ENGINE_ID = "c4874b70a443d49c0";
        #GOOGLE_PSE_API_KEY = "AIzaSyBLMo0e3mpJdna7BPfrsUk7YCz5sQeo2ok";

        OLLAMA_API_BASE_URL = "http://localhost:11434";
        # Disable authentication
        WEBUI_AUTH = "False";
      };
    };
    # ollama run llava:13b, there is more you should do, like set up a UI interface? https://github.com/mschwaig/nixpkgs/tree/open-webui

    # makeDesktopItem https://discourse.nixos.org/t/proper-icon-when-using-makedesktopitem/32026
    # Syncthing desktop shortcut
    environment.systemPackages =
      with pkgs;
      let
        open-webui = makeDesktopItem {
          name = "Ollama open WebUI";
          desktopName = "Ollama open WebUI";
          genericName = "Ollama open WebUI";
          exec = ''brave "http://localhost:11111/?web-search=true"'';
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
        open-webui

        oterm # a text-based terminal client for Ollama 
      ];

  };
}
