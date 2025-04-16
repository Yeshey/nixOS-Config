{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.openvscodeServer;
  certDir = "/var/lib/caddy/certs";
in
{
  options.toHost.openvscodeServer = {
    enable = (lib.mkEnableOption "openvscodeServer");
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Internal port for openvscode-server";
    };
    externalPort = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = "External HTTPS port";
    };
  };

  config = lib.mkIf cfg.enable {

    # Why does this not work here???
    #nixpkgs.config = {
    #   permittedInsecurePackages = [ # for package openvscode-server
    #                  "nodejs-16.20.0"
    #                ];
    #};

    # Generate self-signed certificate (run once manually or use a service)
    environment.systemPackages = [ pkgs.openssl ];
    systemd.services.generate-certs = {
      description = "Generate self-signed certificates";
      wantedBy = [ "multi-user.target" ];
      before = [ "caddy.service" ];
      script = ''
        mkdir -p ${certDir}
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
          -keyout ${certDir}/key.pem \
          -out ${certDir}/cert.pem \
          -days 365 -nodes \
          -subj '/CN=${cfg.hostname}'
      '';
      serviceConfig.Type = "oneshot";
    };

    services.caddy = {
      enable = true;
      virtualHosts."https://${cfg.hostname}" = {
        extraConfig = ''
          tls ${certDir}/cert.pem ${certDir}/key.pem
          reverse_proxy http://127.0.0.1:${toString cfg.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
    };

    # journalctl -fu openvscode-server.service
    # connect to the VScodium server with `ssh -L 9090:localhost:3000 yeshey@143.47.53.175`, and go to http://localhost:9090 in your browser
    # This seems to work:
    # (ssh -L 9090:localhost:3000 -t yeshey@143.47.53.175 "sleep 90" &) && xdg-open http://localhost:9090
    services.openvscode-server = {
      enable = true;
      # package = pkgs.code-server;
      # host = "localhost";
      host = "0.0.0.0"; # Bind to all network interfaces
      port = cfg.port;
      user = "yeshey"; # TODO user variable?
      extensionsDir = "/home/yeshey/.vscode-oss/extensions"; # TODO user variable?
      withoutConnectionToken = true; # So you don't need to grab the token that it generates here
      # extraArguments = [ "--cert" ]; # Generates self-signed certificate
    };

    systemd.services.openvscode-server = {
      path = [
        pkgs.openssl
      ];
    };

    # Ensure certificate directory exists with proper permissions
    #systemd.services.openvscode-server.preStart = ''
    #  mkdir -p /home/yeshey/.local/share/code-server
    #  chown yeshey:users /home/yeshey/.local/share/code-server
    #'';

    networking.firewall.allowedTCPPorts = [
      cfg.externalPort

      # these are needed for remote-ssh, idk if I even need them here
      80
      443
    ];

    # Ensure proper permissions for certificate directory
    systemd.tmpfiles.rules = [
      "d ${certDir} 0755 caddy caddy - -"
    ];
  };
}
