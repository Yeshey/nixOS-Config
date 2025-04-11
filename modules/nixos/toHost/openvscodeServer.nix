{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.openvscodeServer;
in
{
  options.toHost.openvscodeServer = {
    enable = (lib.mkEnableOption "openvscodeServer");
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      example = 3001;
      description = "port to run vscode-server on";
    };
    desktopItem = {
      enable = lib.mkEnableOption "desktopItem";
      remote = lib.mkOption {
        type = lib.types.str;
        default = "oracle";
        example = "oracle";
        description = "Makes a desktop entry to the openvscode-server";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    # Why does this not work here???
    #nixpkgs.config = {
    #   permittedInsecurePackages = [ # for package openvscode-server
    #                  "nodejs-16.20.0"
    #                ];
    #};

    # journalctl -fu openvscode-server.service
    # connect to the VScodium server with `ssh -L 9090:localhost:3000 yeshey@143.47.53.175`, and go to http://localhost:9090 in your browser
    # This seems to work:
    # (ssh -L 9090:localhost:3000 -t yeshey@143.47.53.175 "sleep 90" &) && xdg-open http://localhost:9090
    services.openvscode-server = {
      enable = true;
      host = "localhost";
      port = cfg.port;
      user = "yeshey"; # TODO user variable?
      extensionsDir = "/home/yeshey/.vscode-oss/extensions"; # TODO user variable?
      withoutConnectionToken = true; # So you don't need to grab the token that it generates here
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  } // lib.mkIf cfg.desktopItem.enable {
    # makeDesktopItem https://discourse.nixos.org/t/proper-icon-when-using-makedesktopitem/32026
    environment.systemPackages = with pkgs;     let 
        govscodeserver = pkgs.writeShellScriptBin "govscodeserver" ''
          (ssh -L ${toString cfg.port}:localhost:${toString cfg.port} -t ${cfg.desktopItem.remote} "sleep 90" &) && sleep 1.5 && xdg-open "http://localhost:${toString cfg.port}/?folder=/home/yeshey/.setup"
        '';
    in [
      xdg-utils
      (makeDesktopItem {
        name = "Oracle vscode-server";
        desktopName = "Oracle vscode-server";
        genericName = "Oracle vscode-server";
        # Build a command that forwards the port and then opens the browser against the correct URL.
        exec = "${govscodeserver}/bin/govscodeserver";
        icon = "vscode"; # Change this to a suitable icon if you prefer
        categories = [
          "GTK"
          "X-WebApps"
        ];
        mimeTypes = [
          "text/html"
          "text/xml"
          "application/xhtml_xml"
        ];
      })
    ];
  };
}
