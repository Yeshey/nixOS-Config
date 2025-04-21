# helpful links
# https://caddy.community/t/reverse-proxy-without-domain-name/7951/24
# https://nodeployfriday.com/posts/self-signed-cert/

# also only connects with firefox 

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
    internalPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Internal port for openvscode-server";
    };
    externalPort = lib.mkOption {
      type = lib.types.port;
      default = 8443; # seems to need to be this port
      description = "External HTTPS port";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      #default = "143.47.53.175";
      default = "143.47.53.175";
      description = "Domain name for HTTPS certificate";
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.services."caddy".preStart =  let
        confFile = pkgs.writeText "openssl.conf" ''
          [req]
          distinguished_name = req_distinguished_name
          x509_extensions = v3_req
          prompt = no
          req_extensions = v3_req

          [req_distinguished_name]
          CN = ${cfg.hostname}

          [v3_req]
          keyUsage = keyEncipherment, dataEncipherment
          extendedKeyUsage = serverAuth
          subjectAltName = @alt_names

          [alt_names]
          IP.1 = ${cfg.hostname}
        '';
      in ''
        mkdir -p ${certDir}
        chown caddy:caddy ${certDir}
        chmod 0755 ${certDir}

        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
          -config ${confFile} \
          -keyout ${certDir}/key.pem \
          -out ${certDir}/cert.pem \
          -days 365 -nodes \
          -extensions v3_req

        chown caddy:caddy ${certDir}/{cert,key}.pem
        chmod 0640 ${certDir}/{cert,key}.pem
      '';

    services.caddy = {
      enable = true;
      globalConfig = ''
          default_sni ${cfg.hostname}
      '';
      # Listen on all interfaces on the external port
      virtualHosts.":${toString cfg.externalPort}" = {
        extraConfig = ''
          tls ${certDir}/cert.pem ${certDir}/key.pem
          reverse_proxy http://127.0.0.1:${toString cfg.internalPort}
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
      port = cfg.internalPort;
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
      cfg.internalPort

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
