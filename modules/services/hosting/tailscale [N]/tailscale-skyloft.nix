{ inputs, ... }:
{
  flake.modules.nixos.tailscale-skyloft =
    { config, lib, pkgs, ... }:
    let
      hostname = "skyloft.tailb6874b.ts.net";

      # Add HTTPS services here: external port -> local backend.
      httpsServices = {
        "8443" = "http://127.0.0.1:3000";  # Forgejo
        "8444" = "http://127.0.0.1:18789"; # OpenClaw
      };

      serveConfig = pkgs.writeText "skyloft-tailscale-serve.json" (
        builtins.toJSON {
          TCP = lib.mapAttrs (_: _: { HTTPS = true; }) httpsServices;
          Web = lib.mapAttrs' (
            port: backend:
            lib.nameValuePair "${hostname}:${port}" {
              Handlers."/".Proxy = backend;
            }
          ) httpsServices;
        }
      );

      applyServeConfig = pkgs.writeShellScript "apply-skyloft-serve" ''
        exec ${lib.getExe config.services.tailscale.package} serve set-raw < ${serveConfig}
      '';
    in
    {
      imports = with inputs.self.modules.nixos; [
        tailscale
      ];

      networking.nftables.enable = true;

      sops.secrets."tailscale/authkey" = {
        owner = "root";
        group = "root";
        mode = "0400";
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };

      services.tailscale = {
        useRoutingFeatures = "both";
        authKeyFile = config.sops.secrets."tailscale/authkey".path;
        extraUpFlags = [
          "--hostname=skyloft"
          "--advertise-exit-node"
        ];

        serve = {
          enable = true;
          configFile = serveConfig;
        };
      };

      systemd.services.tailscale-serve.serviceConfig.ExecStart =
        lib.mkForce "${applyServeConfig}";

      systemd.services.tailscaled-autoconnect = {
        unitConfig.RequiresMountsFor = config.sops.secrets."tailscale/authkey".path;
        serviceConfig = {
          TimeoutStartSec = "30s";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        startLimitIntervalSec = 120;
        startLimitBurst = 10;
      };

      networking.firewall = {
        trustedInterfaces = [ config.services.tailscale.interfaceName ];
        allowedUDPPorts = [ config.services.tailscale.port ];
      };

      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

      environment.systemPackages = [ pkgs.ethtool ];

      services.networkd-dispatcher = {
        enable = true;
        rules."50-tailscale" = {
          onState = [ "routable" ];
          script = ''
            NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
            ${pkgs.ethtool}/bin/ethtool -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off
          '';
        };
      };
    };
}