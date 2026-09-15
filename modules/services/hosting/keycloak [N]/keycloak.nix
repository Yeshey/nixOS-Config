{ ... }:
{
  flake.modules.nixos.keycloak =
    { config, ... }:
    let
      domain = "netbirdauth.yeshey.dpdns.org";
    in
    {
      sops.secrets."keycloak/db-password" = {
        restartUnits = [ "keycloak.service" ];
      };

      services.keycloak = {
        enable = true;
        initialAdminPassword = "change-me-immediately";  # temporary; change in admin console ASAP

        database = {
          type = "postgresql";
          createLocally = true;  # this is the default
          passwordFile = config.sops.secrets."keycloak/db-password".path;
        };

        settings = {
          hostname = domain;
          http-port = 8090;          # Keycloak listens on 8080 internally
          http-relative-path = "/";  # default; fine for a dedicated subdomain

          http-enabled = true;            # allow plain HTTP listener on 8090
          hostname-strict-https = false;  # don't force HTTPS scheme in generated URLs
          proxy-headers = "xforwarded";   # trust Caddy's X-Forwarded-* headers
        };
      };

      # Caddy vhost — no ACME challenge block needed if you use Caddy's
      # automatic HTTPS. But since you're using security.acme elsewhere,
      # either use useACMEHost or let Caddy handle it. Simplest:
      services.caddy.virtualHosts."${domain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8090
        '';
      };

      # So the server can reach its own Keycloak (same hairpin NAT fix)
      networking.extraHosts = ''
        127.0.0.1 ${domain}
      '';
    };
}