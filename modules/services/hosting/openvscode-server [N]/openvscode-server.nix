{ inputs, ... }:

let
  certDir = "/var/lib/caddy/certs";
in
{
  flake.modules.nixos.openvscode-server =
    { pkgs, lib, config, ... }:
    {
      options.openvscode-server = {
        internalPort = lib.mkOption {
          type    = lib.types.port;
          default = 2998;
        };
        externalPort = lib.mkOption {
          type    = lib.types.port;
          default = 8443;
        };
        hostname = lib.mkOption {
          type    = lib.types.str;
          default = "143.47.53.175";
        };
        user = lib.mkOption {
          type    = lib.types.str;
          default = "yeshey";
        };
      };

      config =
        let cfg = config.openvscode-server; in
        {
          # helpful links:
          # https://caddy.community/t/reverse-proxy-without-domain-name/7951/24
          # connect via: (ssh -L 9090:localhost:3000 -t yeshey@143.47.53.175 "sleep 90" &) && xdg-open http://localhost:9090
          # only connects with firefox (self-signed cert)

          systemd.services.caddy.preStart =
            let
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
            globalConfig = "default_sni ${cfg.hostname}";
            virtualHosts.":${toString cfg.externalPort}".extraConfig = ''
              tls ${certDir}/cert.pem ${certDir}/key.pem
              reverse_proxy http://127.0.0.1:${toString cfg.internalPort}
            '';
          };

          services.openvscode-server = {
            enable                  = true;
            package                 = pkgs.code-server;
            host                    = "0.0.0.0";
            port                    = cfg.internalPort;
            user                    = cfg.user;
            extensionsDir           = "/home/${cfg.user}/.vscode-oss/extensions";
            withoutConnectionToken  = true;
          };

          systemd.services.openvscode-server.path = [ pkgs.openssl ];

          systemd.tmpfiles.rules = [
            "d ${certDir} 0755 caddy caddy - -"
          ];

          networking.firewall.allowedTCPPorts = [
            cfg.externalPort
            cfg.internalPort
            80
            443
          ];
        };
    };
}