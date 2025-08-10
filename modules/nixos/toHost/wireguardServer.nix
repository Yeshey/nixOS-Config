# see pub key: sudo wg show wgOracle
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
  config = lib.mkMerge [
    
    (lib.mkIf (cfg.enable) { 
      environment.systemPackages = [
        pkgs.networkmanager
        pkgs.networkmanagerapplet # Adds nm-connection-editor
        pkgs.wireguard-tools # Allows using wg and wg-quick commands
      ];
      # Prevent NetworkManager (GNOME) from managing WireGuard interfaces
      networking.networkmanager.unmanaged = [ "wgOracle" ]; # bc if you disconnected it in gnome it would go away forever

      # enable NAT
      #networking.nat.enable = true;
      #networking.nat.externalInterface = "eth0";
      #networking.nat.internalInterfaces = [ "wgOracle" ];
      networking.firewall = {
        allowedUDPPorts = [ 51820 ];
      };

      networking.wireguard.enable = true;
      networking.wireguard.interfaces = {
        # "wgOracle" is the network interface name. You can name the interface arbitrarily.
        wgOracle = {
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
              publicKey = "mhfuwWbBmZqw9WEDh8a4ce3IgMa/0YsFTf18jkw3Ezc="; # "{client public key}"; # use sudo wg show wgOracle
              # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
              allowedIPs = [ "10.100.0.2/32" ];
            }
            # { 
              # ...
            # }
          ];
        };
      };
    })
    
    (lib.mkIf (cfg.enable && config.mySystem.impermanence.enable) {
      environment.persistence."/persistent" = {
        directories = [
          "/etc/wireguard/"
        ];
      };
    })
  ];
}
