{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.ollama;
in
{
  options.mySystem.ollama = {
    enable = lib.mkEnableOption "ollama";
    acceleration = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null; # Default is null
      description = "Acceleration type (e.g., 'cuda' or 'rocm'), or null to use the default.";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable)  {

    services.ollama = {
      package = pkgs.unstable.ollama;
      enable = true;
      acceleration = if cfg.acceleration == null then null else cfg.acceleration;
    };
    # systemctl status open-webui
    services.open-webui = {
      package = pkgs.unstable.open-webui;
      enable = true;
      openFirewall = true;
      port = 11111;
      environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
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
          exec = ''xdg-open "http://127.0.0.1:11111/"'';
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
