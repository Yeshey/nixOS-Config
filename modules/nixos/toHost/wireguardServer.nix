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
  cfg = config.toHost.wireguardServer;
in
{
  options.toHost.wireguardServer = with lib; {
    enable = mkEnableOption "wireguardServer";
  };

  # always active lib.mkIf (config.toHost.enable && cfg.enable) 
  config = lib.mkIf (cfg.enable) { 

    # enable NAT
    #networking.nat.enable = true;
    #networking.nat.externalInterface = "eth0";
    #networking.nat.internalInterfaces = [ "wg0" ];
    networking.firewall = {
      allowedUDPPorts = [ 51820 ];
    };

    networking.wireguard.enable = true;
    networking.wireguard.interfaces = {
      # "wg0" is the network interface name. You can name the interface arbitrarily.
      wg0 = {
        # Determines the IP address and subnet of the server's end of the tunnel interface.
        ips = [ "10.100.0.1/24" ];

        # The port that WireGuard listens to. Must be accessible by the client.
        listenPort = 51820;

        # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
        # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
        '';

        # This undoes the above command
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
        '';

        generatePrivateKeyFile = true;
        privateKeyFile = "/etc/wireguard/server.key";

        peers = [
          # List of allowed peers.
          { 
            # Feel free to give a meaningful name
            name = "hyruleCastleYeshey";
            # Public key of the peer (not a file path).
            publicKey = "mhfuwWbBmZqw9WEDh8a4ce3IgMa/0YsFTf18jkw3Ezc="; # "{client public key}"; # use sudo wg show wg0
            # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
            allowedIPs = [ "10.100.0.2/32" ];
          }
          # { 
            # ...
          # }
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
