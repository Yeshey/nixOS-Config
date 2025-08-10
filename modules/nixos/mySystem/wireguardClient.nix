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
  cfg = config.mySystem.wireguardClient;
  port = 51820;
in
{
  options.mySystem.wireguardClient = with lib; {
    enable = mkEnableOption "wireguardClient";
  };

  # always active lib.mkIf (config.mySystem.enable && cfg.enable) 
  config = lib.mkMerge [
    
    (lib.mkIf (config.mySystem.enable && cfg.enable) { 
      environment.systemPackages = [
        pkgs.networkmanager
        pkgs.networkmanagerapplet # Adds nm-connection-editor
        pkgs.wireguard-tools # Allows using wg and wg-quick commands
      ];
      # Prevent NetworkManager (GNOME) from managing WireGuard interfaces
      networking.networkmanager.unmanaged = [ "wgOracle" ]; # bc if you disconnected it in gnome it would go away forever

      networking.firewall = {
        allowedUDPPorts = [ port ]; # Clients and peers can use the same port, see listenport
      };
      # Enable WireGuard
      networking.wireguard.enable = true;
      networking.wireguard.interfaces = {
        # "wgOracle" is the network interface name. You can name the interface arbitrarily.
        wgOracle = {
          # Determines the IP address and subnet of the client's end of the tunnel interface.
          ips = [ "10.100.0.2/24" ];
          listenPort = port; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

          generatePrivateKeyFile = true;
          privateKeyFile = "/etc/wireguard/client.key";

          peers = [
            # For a client configuration, one peer entry for the server will suffice.

            {
              name = "OracleServer";
              # Public key of the server (not a file path).
              publicKey = "tFnVEEbaOZu4qW+SigRWx9cyaYuhl03M0+MLUYsgZ2I="; # "{server public key}"; # # use sudo wg show wgOracle 

              # Forward all the traffic via VPN.
              # allowedIPs = [ "0.0.0.0/0" ];
              allowedIPs = [ "10.100.0.1/32" ]; # set this instead of the one above, because all traffic was being redirected to the VPN
              # Or forward only particular subnets
              #allowedIPs = [ "10.100.0.1" "91.108.12.0/22" ];

              # Set this to the server IP and port.
              endpoint = "143.47.53.175:${toString port}"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

              # Send keepalives every 25 seconds. Important to keep NAT tables alive.
              persistentKeepalive = 25;
            }
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
