{ config, lib, pkgs, ... }:

let
  cfg = config.toHost.wireguardVPN;
  wgPort = 51821;           # pick any free UDP port
  wgNet = "10.99.99.0/24";  # VPN subnet
  wgInterface = "wgvpn";    # kernel interface name
in
{
  options.toHost.wireguardVPN = with lib; {
    enable = mkEnableOption "wireguardVPN server (NetworkManager compatible)";
  };

  config = lib.mkMerge [
  
    (lib.mkIf cfg.enable {

      # 1. Kernel-level WireGuard
      networking.wireguard.enable = true;
      networking.wireguard.interfaces.${wgInterface} = {
        ips = [ "10.99.99.1/24" ]; # Server gets .1, client gets .10
        listenPort = wgPort;
        generatePrivateKeyFile = true;
        privateKeyFile = "/etc/wireguard/${wgInterface}.key";
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -C POSTROUTING -o enp0s6 -j MASQUERADE 2>/dev/null || \
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o enp0s6 -j MASQUERADE
        '';
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -o enp0s6 -j MASQUERADE 2>/dev/null || true
        '';
        # Peers will be added later per-client
        peers = [
          {
            # Your laptop/client
            name = "hyruleCastleYeshey";
            publicKey = "XxQBlzUpsyEN1jAX6W9j4fA7YJeLP/3foRI8r+T97EI=";  # sudo wg show wgvpn
            allowedIPs = [ "10.99.99.10/32" ];
          }
        ];
      };

      # 2. Firewall
      networking.firewall = {
        allowedUDPPorts = [ wgPort ];
      };

      # 3. IP forwarding
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

      # 4. Convenience packages
      environment.systemPackages = with pkgs; [
        wireguard-tools
      ];
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

/*
On the server, generate one file per laptop/phone:

```bash
# 1. Create client keypair
wg genkey | tee client.key | wg pubkey > client.pub
# 2. Read server public key
export SERVER_PUB=$(sudo wg show wgvpn public-key)
# 3. Pick an unused IP from 10.99.99.0/24
export CLIENT_IP="10.99.99.10/32"
export SERVER_PUBLIC_IP=143.47.53.175
```

Create skyloftvpn.conf:
```bash
cat > skyloftvpn.conf <<EOF
[Interface]
PrivateKey = $(cat client.key)
Address = $CLIENT_IP
DNS = 1.1.1.1, 1.0.0.1

[Peer]
PublicKey = $SERVER_PUB
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $SERVER_PUBLIC_IP:51821
PersistentKeepalive = 25
EOF
```

Then generate the public key from your client private key, so if you get:
[Interface]
PrivateKey = KA8LYv7mkqgslNeojEn+SItAIVEhg3ie7ZMPDZ8XwEE=

Then do echo "KA8LYv7mkqgslNeojEn+SItAIVEhg3ie7ZMPDZ8XwEE=" | wg pubkey

and add the result above in the peers = [... section

Copy this file to your GNOME laptop and import from file...
 */