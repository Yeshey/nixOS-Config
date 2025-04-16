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
      default = 8443;
      description = "Remote port number to use for reverse SSH tunneling";
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
      # package = pkgs.code-server;
      host = "localhost";
      port = cfg.port;
      user = "yeshey"; # TODO user variable?
      extensionsDir = "/home/yeshey/.vscode-oss/extensions"; # TODO user variable?
      withoutConnectionToken = true; # So you don't need to grab the token that it generates here
    };

    networking.firewall.allowedTCPPorts = [
      cfg.port

      # these are needed for remote-ssh, idk if I even need them here
      80
      443
    ];
  };
}
