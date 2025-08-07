# see pub key: sudo wg show wg0
# helped by deepseek
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.wireguardClient;
  port = 51820;
in
{
  options.mySystem.wireguardClient = with lib; {
    enable = mkEnableOption "wireguardClient";
  };

  # always active lib.mkIf (config.mySystem.enable && cfg.enable) 
  config = lib.mkIf (config.mySystem.enable && cfg.enable) { 

    networking.firewall = {
      allowedUDPPorts = [ port ]; # Clients and peers can use the same port, see listenport
    };
    # Enable WireGuard
    networking.wireguard.enable = true;
    networking.wireguard.interfaces = {
      # "wg0" is the network interface name. You can name the interface arbitrarily.
      wg0 = {
        # Determines the IP address and subnet of the client's end of the tunnel interface.
        ips = [ "10.100.0.2/24" ];
        listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

        generatePrivateKeyFile = true;
        privateKeyFile = "/etc/wireguard/client.key";

        peers = [
          # For a client configuration, one peer entry for the server will suffice.

          {
            name = "OracleServer";
            # Public key of the server (not a file path).
            publicKey = ""; # "{server public key}"; # # use sudo wg show wg0 

            # Forward all the traffic via VPN.
            allowedIPs = [ "0.0.0.0/0" ];
            # Or forward only particular subnets
            #allowedIPs = [ "10.100.0.1" "91.108.12.0/22" ];

            # Set this to the server IP and port.
            endpoint = "143.47.53.175:${port}"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

            # Send keepalives every 25 seconds. Important to keep NAT tables alive.
            persistentKeepalive = 25;
          }
        ];
      };
    };

    environment.persistence."/persistent" = {
      directories = [
        "/etc/wireguard/"
      ];
    };

  };
}
