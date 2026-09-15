{ ... }:
{
  flake.modules.nixos.netbird =
    { config, ... }:
    let
      # TODO: public domain, DNS A/AAAA -> 143.47.53.175. Coturn reuses the
      # same domain (server.nix defaults coturn.domain to cfg.domain), so
      # only one DNS record and one set of certs are needed.
      domain = "netbird.yeshey.dpdns.org";

      managementPort = config.services.netbird.server.management.port; # 8011
      signalPort = config.services.netbird.server.signal.port; # 8012

      # TODO: stand up a Keycloak realm (native services.keycloak, next
      # module) with two clients before this actually lets anyone log in:
      #   - "netbird-mgmt": confidential, client_credentials grant, used by
      #     IdpManagerConfig to sync/lookup users server-side.
      #   - "netbird-client": public, used by the dashboard/CLI for the PKCE
      #     login flow. No secret needed (matches dashboard's forced-empty
      #     AUTH_CLIENT_SECRET below).
      # Until that exists, management still starts (oidcConfigEndpoint just
      # needs to resolve to *something* valid), but nobody can log in.
      # oidcIssuer = "https://netbird.yeshey.dpdns.org/realms/netbird";
      oidcIssuer = "https://netbirdauth.yeshey.dpdns.org/realms/netbird";
    in
    {
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      security.acme.acceptTerms = true;
      networking.extraHosts = ''
        127.0.0.1 netbird.yeshey.dpdns.org
      '';

      # Generate once:
      #   openssl rand -base64 32   -> data-store-encryption-key
      #   pwgen / openssl rand -hex 24 -> coturn-password (shared: coturn's
      #     own static user AND management's TURNConfig.Turns[0].Password —
      #     server.nix wires this automatically, don't duplicate it)
      sops.secrets."netbird/data-store-encryption-key" = {
        restartUnits = [ "netbird-management.service" ];
      };
      sops.secrets."netbird/coturn-password" = {
        owner = "turnserver";
        mode = "0400";
        restartUnits = [
          "coturn.service"
          "netbird-management.service"
        ];
      };
      sops.secrets."netbird/idp-client-secret" = {
        restartUnits = [ "netbird-management.service" ];
      };

      services.netbird.server = {
        enable = true;
        domain = domain;
        # Caddy already owns :443 on this host for other vhosts; nginx and
        # Caddy can't share it, so every sub-service's own nginx stays off
        # and Caddy fronts management/signal/dashboard manually below.
        enableNginx = false;

        coturn = {
          enable = true;
          passwordFile = config.sops.secrets."netbird/coturn-password".path;
          useAcmeCertificates = true; # needs security.acme.certs.${domain}, wired below
        };

        management = {
          oidcConfigEndpoint = "${oidcIssuer}/.well-known/openid-configuration";
          disableAnonymousMetrics = true;

          settings = {
            DataStoreEncryptionKey._secret = config.sops.secrets."netbird/data-store-encryption-key".path;

            TURNConfig.Secret._secret = config.sops.secrets."netbird/coturn-password".path;

            IdpManagerConfig = {
              ManagerType = "keycloak";
              ClientConfig = {
                Issuer = oidcIssuer;
                TokenEndpoint = "${oidcIssuer}/protocol/openid-connect/token";
                ClientID = "netbird-mgmt";
                ClientSecret._secret = config.sops.secrets."netbird/idp-client-secret".path;
                GrantType = "client_credentials";
              };
              ExtraConfig.AdminEndpoint = "https://netbirdauth.yeshey.dpdns.org/admin/realms/netbird";
            };

            PKCEAuthorizationFlow.ProviderConfig = {
              Audience = "netbird";
              ClientID = "netbird-client";
              AuthorizationEndpoint = "${oidcIssuer}/protocol/openid-connect/auth";
              TokenEndpoint = "${oidcIssuer}/protocol/openid-connect/token";
              RedirectURLs = [ "https://${domain}/nb-auth" ];
            };
          };
        };

        signal = { };

        dashboard.settings = {
          AUTH_AUTHORITY = oidcIssuer;
          AUTH_AUDIENCE = "netbird";
          AUTH_CLIENT_ID = "netbird-client";
          AUTH_REDIRECT_URI = "/nb-auth";
          AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
        };
      };

      # coturn.nix expects a *NixOS-native* ACME cert object for this domain
      # (it reads security.acme.certs.${domain}.directory directly) — this
      # is separate from whatever Caddy does internally for its own TLS on
      # the same domain. Webroot mode piggybacks on the Caddy vhost below.
      # If you already issue certs via DNS-01 elsewhere on this host, swap
      # this for a dnsProvider block instead — cleaner, no webroot dance.
      security.acme.certs.${domain}.webroot = "/var/lib/acme/challenges/${domain}";

      services.caddy.enable = true;
      services.caddy.virtualHosts."${domain}" = {
        useACMEHost = domain;
        extraConfig = ''
          handle /.well-known/acme-challenge/* {
            root * /var/lib/acme/challenges/${domain}
            file_server
          }

          handle /api/* {
            reverse_proxy 127.0.0.1:${toString managementPort}
          }

          handle /management.ManagementService/* {
            reverse_proxy h2c://127.0.0.1:${toString managementPort}
          }

          handle /signalexchange.SignalExchange/* {
            reverse_proxy h2c://127.0.0.1:${toString signalPort}
          }

          handle {
            root * ${config.services.netbird.server.dashboard.finalDrv}
            try_files {path} {path}.html {path}/ /404.html
            file_server
          }
        '';
      };
    };
}