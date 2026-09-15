{ inputs, ... }:
{
  flake.modules.nixos.tailscale-skyloft =
   { config, pkgs, ... }:
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
      };

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