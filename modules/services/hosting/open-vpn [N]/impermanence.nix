{ inputs, ... }:
{
  flake.modules.nixos.open-vpn =
    { config, ... }:
    {
      environment = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [
            "/etc/openvpn"
            "/var/lib/openvpn"
            "/var/log/openvpn"
          ];
        };
      };
    };
}