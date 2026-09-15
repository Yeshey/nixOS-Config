{ ... }:
{
  flake.modules.nixos.headscale =
    { config, pkgs, ... }:
    {
      sops.secrets."tailscale/authkey" = {
        owner = "root";
        group = "root";
        mode = "0400";
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        authKeyFile = config.sops.secrets."tailscale/authkey".path;
        extraUpFlags = [
          "--login-server=https://headscale.yeshey.dpdns.org"
          "--hostname=skyloft"
          "--advertise-exit-node"
          "--reset"
        ];
      };

      networking.firewall = {
        trustedInterfaces = [ config.services.tailscale.interfaceName ];
        allowedUDPPorts = [ config.services.tailscale.port ];
      };
    };
}