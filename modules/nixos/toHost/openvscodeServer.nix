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
    # c
    services.openvscode-server = {
      enable = true;
      host = "localhost";
      #host = "0.0.0.0"; # Allow connections from all network interfaces
      port = 3000;
      user = "yeshey"; # TODO user variable?
      extensionsDir = "/home/yeshey/.vscode-oss/extensions"; # TODO user variable?
      withoutConnectionToken = true; # So you don't need to grab the token that it generates here
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
      3000 # question mark
    ];
  };
}
