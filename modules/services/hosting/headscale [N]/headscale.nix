{ ... }:
{
  flake.modules.nixos.headscale =
    { config, pkgs, ... }:
    let
      domain = "headscale.yeshey.dpdns.org";
      port = 8080;
      derpPort = 8443;
      publicIPv4 = "143.47.53.175";

      aclConfig = {
        groups = { "group:admin" = [ "yeshey@" ]; };
        tagOwners = {
          "tag:server" = [ "group:admin" ];
          "tag:friend" = [ "group:admin" ];
        };
        autoApprovers = {
          routes = {
            "0.0.0.0/0" = [ "tag:server" ];
            "::/0" = [ "tag:server" ];
          };
          exitNode = [ "tag:server" ];
        };
        acls = [
          { action = "accept"; src = [ "group:admin" ]; dst = [ "*:*" ]; }
          { action = "accept"; src = [ "tag:server" ]; dst = [ "*:*" ]; }
          { action = "accept"; src = [ "tag:friend" ]; dst = [ "tag:server:443" ]; }
        ];
      };
      aclFile = pkgs.writeText "headscale-acl.hujson" (builtins.toJSON aclConfig);
    in
    {
      # --- sops secrets for the two private keys ---
      sops.secrets."headscale/noise_private_key" = {
        owner = "headscale";
        group = "headscale";
        mode = "0400";
        restartUnits = [ "headscale.service" ];
      };

      sops.secrets."headscale/derp_server_private_key" = {
        owner = "headscale";
        group = "headscale";
        mode = "0400";
        restartUnits = [ "headscale.service" ];
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 80 443 derpPort ];
        allowedUDPPorts = [ 3478 ];
        trustedInterfaces = [ "tailscale0" ];
      };

      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

      environment.systemPackages = [ pkgs.ethtool ];

      services.networkd-dispatcher = {
        enable = true;
        rules."50-tailscale" = {
          onState = [ "routable" ];
          script = ''
            ${pkgs.ethtool}/bin/ethtool -K "$1" rx-udp-gro-forwarding on rx-gro-list off
          '';
        };
      };

      systemd.services.headscale-ensure-admin = {
        description = "Ensure Headscale admin user exists";
        after = [ "headscale.service" ];
        requires = [ "headscale.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "headscale";
          Group = "headscale";
        };
        script = ''
          if ! ${pkgs.headscale}/bin/headscale users list | grep -q "yeshey"; then
            ${pkgs.headscale}/bin/headscale users create yeshey
          fi
        '';
      };

      services.headscale = {
        enable = true;
        address = "127.0.0.1";
        port = port;

        settings = {
          server_url = "https://${domain}";

          database = {
            type = "sqlite";
            sqlite.path = "/var/lib/headscale/db.sqlite";
          };

          dns = {
            magic_dns = true;
            base_domain = "ts";
            nameservers.global = [ "1.1.1.1" "8.8.8.8" ];
          };

          # Both keys now come from sops
          noise.private_key_path =
            config.sops.secrets."headscale/noise_private_key".path;

          derp = {
            urls = [ "https://controlplane.tailscale.com/derpmap/default" ];
            auto_update_enabled = true;
            update_frequency = "24h";

            server = {
              enabled = true;
              region_id = 999;
              region_code = "skyloft";
              region_name = "Skyloft Embedded DERP";
              stun_listen_addr = "0.0.0.0:3478";
              private_key_path =
                config.sops.secrets."headscale/derp_server_private_key".path;
              automatically_add_embedded_derp_region = true;
              ipv4 = publicIPv4;
            };
          };

          policy = {
            mode = "file";
            path = "${aclFile}";
          };

          log = { level = "info"; format = "text"; };
        };
      };

      services.caddy.virtualHosts."${domain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString port}
        '';
      };

      networking.extraHosts = ''
        127.0.0.1 ${domain}
      '';
    };
}