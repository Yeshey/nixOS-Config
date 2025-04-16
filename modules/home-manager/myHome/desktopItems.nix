{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.myHome.desktopItems;
in
{
  options.myHome.desktopItems = with lib; {
    xrdp = {
      enable = mkEnableOption "xrdp desktop item";
      remote = {
        ip = mkOption {
          type = types.str;
          default = "143.47.53.175";
          description = "IP address of the remote host";
        };
        user = mkOption {
          type = types.str;
          default = "yeshey";
          description = "Username for the remote host";
        };
      };
      extraclioptions = mkOption {
        type = types.str;
        default = "/dynamic-resolution /kbd:0x0816 /audio-mode:1 /clipboard /network:modem /compression";
        description = "Extra command line options for xfreerdp";
      };
    };
    openvscodeServer = {
      enable = mkEnableOption "openvscodeServer desktop item";
      remote = mkOption {
        type = types.str;
        default = "oracle";
        description = "Remote hostname for openvscode-server";
      };
      port = mkOption {
        type = types.port;
        default = 9443;
        description = "Port to run openvscode-server on";
      };
    };
  };

  config = lib.mkMerge [
    {
      home.packages = [
        pkgs.cmatrix
      ];
    }
    (lib.mkIf (config.myHome.enable && cfg.xrdp.enable) {
      home.packages = let
        gofreerdp = pkgs.writeShellScriptBin "gofreerdpserver" ''
          ${pkgs.freerdp}/bin/xfreerdp /v:${cfg.xrdp.remote.ip} /u:${cfg.xrdp.remote.user} ${cfg.xrdp.extraclioptions}
        '';
        freerdpDesktopItem = pkgs.makeDesktopItem {
          name = "FreeRDP Oracle";
          desktopName = "FreeRDP Oracle";
          genericName = "FreeRDP Oracle";
          exec = "${gofreerdp}/bin/gofreerdpserver";
          icon = (pkgs.fetchurl {
            url = "https://github.com/FreeRDP/FreeRDP/raw/master/client/iOS/Resources/Icon.png";
            sha256 = "0arbqzzzcmd5m0ysdpydr2mm734vmldjjjbydf1p8njld4kz2klm";
          });
          categories = [ "GTK" "X-WebApps" ];
          mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
        };
      in [ pkgs.freerdp pkgs.xdg-utils gofreerdp freerdpDesktopItem ];
    })
    (lib.mkIf (config.myHome.enable && cfg.openvscodeServer.enable) {
      home.packages = let
        govscodeserver = pkgs.writeShellScriptBin "govscodeserver" ''
          (ssh -L ${toString cfg.openvscodeServer.port}:localhost:${toString cfg.openvscodeServer.port} -t ${cfg.openvscodeServer.remote} "sleep 90" &) && sleep 1.5 && xdg-open "http://localhost:${toString cfg.openvscodeServer.port}/?folder=/home/yeshey/.setup"
        '';
        vscodeserverDesktopItem = pkgs.makeDesktopItem {
          name = "Oracle vscode-server";
          desktopName = "Oracle vscode-server";
          genericName = "Oracle vscode-server";
          exec = "${govscodeserver}/bin/govscodeserver";
          icon = "vscode";
          categories = [ "GTK" "X-WebApps" ];
          mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
        };
      in [ pkgs.openssh pkgs.xdg-utils govscodeserver vscodeserverDesktopItem ];
    })
  ];
}