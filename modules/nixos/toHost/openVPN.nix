# Need to port forward:
# - UDP 1194 (for UDP connections)
# - TCP 443 (for TCP connections - uses HTTPS port to bypass firewalls)

{ config, lib, pkgs, ... }:
let
  cfg = config.toHost.openVPN;
  vpnPortUDP = 1194; # standard OpenVPN UDP port
  vpnPortTCP = 443;  # HTTPS port - less likely to be blocked
  vpnNetUDP = "10.8.0.0/24"; # VPN subnet for UDP
  vpnNetTCP = "10.8.1.0/24"; # VPN subnet for TCP (different to avoid conflicts)
  vpnInterfaceUDP = "tun0"; # OpenVPN UDP interface name
  vpnInterfaceTCP = "tun1"; # OpenVPN TCP interface name
  serverIPUDP = "10.8.0.1"; # Server IP in UDP VPN subnet
  serverIPTCP = "10.8.1.1"; # Server IP in TCP VPN subnet
  externalInterface = "enp0s6"; # Your external network interface
  
  # Paths for keys and certificates
  serverKeyDir = "/etc/openvpn/server";
  caPath = "${serverKeyDir}/ca.crt";
  certPath = "${serverKeyDir}/server.crt";
  keyPath = "${serverKeyDir}/server.key";
  dhPath = "${serverKeyDir}/dh2048.pem";
  taPath = "${serverKeyDir}/ta.key";
in
{
  options.toHost.openVPN = with lib; {
    enable = mkEnableOption "OpenVPN server (UDP + TCP, NetworkManager compatible)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # 1. OpenVPN UDP Server Configuration (Primary - Faster)
      services.openvpn.servers.skyloftVPN-UDP = {
        autoStart = true;
        config = ''
          # Server mode
          mode server
          tls-server
          
          # Protocol and port
          proto udp
          port ${toString vpnPortUDP}
          dev ${vpnInterfaceUDP}
          dev-type tun
          
          # Network configuration
          topology subnet
          server 10.8.0.0 255.255.255.0
          ifconfig-pool-persist /var/lib/openvpn/ipp-udp.txt
          
          # Certificates and keys
          ca ${caPath}
          cert ${certPath}
          key ${keyPath}
          dh ${dhPath}
          tls-auth ${taPath} 0
          
          # Security settings
          cipher AES-256-GCM
          auth SHA256
          tls-version-min 1.2
          
          # Client configuration
          push "redirect-gateway def1 bypass-dhcp"
          push "dhcp-option DNS 1.1.1.1"
          push "dhcp-option DNS 1.0.0.1"
          
          # Connection settings
          keepalive 10 120
          persist-key
          persist-tun
          
          # Logging
          verb 3
          status /var/log/openvpn/status-udp.log
          log-append /var/log/openvpn/openvpn-udp.log
          
          # Performance
          comp-lzo
          
          # User and group (drop privileges)
          user nobody
          group nogroup
        '';
      };

      # 2. OpenVPN TCP Server Configuration (Fallback - For Restricted Networks)
      services.openvpn.servers.skyloftVPN-TCP = {
        autoStart = true;
        config = ''
          # Server mode
          mode server
          tls-server
          
          # Protocol and port - TCP on port 443 (HTTPS) to bypass firewalls
          proto tcp-server
          port ${toString vpnPortTCP}
          dev ${vpnInterfaceTCP}
          dev-type tun
          
          # Network configuration - different subnet to avoid conflicts
          topology subnet
          server 10.8.1.0 255.255.255.0
          ifconfig-pool-persist /var/lib/openvpn/ipp-tcp.txt
          
          # Certificates and keys (same as UDP)
          ca ${caPath}
          cert ${certPath}
          key ${keyPath}
          dh ${dhPath}
          tls-auth ${taPath} 0
          
          # Security settings
          cipher AES-256-GCM
          auth SHA256
          tls-version-min 1.2
          
          # Client configuration
          push "redirect-gateway def1 bypass-dhcp"
          push "dhcp-option DNS 1.1.1.1"
          push "dhcp-option DNS 1.0.0.1"
          
          # Connection settings
          keepalive 10 120
          persist-key
          persist-tun
          
          # Logging
          verb 3
          status /var/log/openvpn/status-tcp.log
          log-append /var/log/openvpn/openvpn-tcp.log
          
          # Performance
          comp-lzo
          
          # User and group (drop privileges)
          user nobody
          group nogroup
        '';
      };

      # 3. Firewall configuration
      networking.firewall = {
        allowedUDPPorts = [ vpnPortUDP ];
        allowedTCPPorts = [ vpnPortTCP ];
        trustedInterfaces = [ vpnInterfaceUDP vpnInterfaceTCP ];
      };

      # 4. NAT configuration for internet routing
      networking.nat = {
        enable = true;
        externalInterface = externalInterface;
        internalInterfaces = [ vpnInterfaceUDP vpnInterfaceTCP ];
      };

      # 5. IP forwarding
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

      # 6. Convenience packages
      environment.systemPackages = with pkgs; [
        openvpn
        easyrsa
      ];

      # 7. Create necessary directories
      systemd.tmpfiles.rules = [
        "d /var/log/openvpn 0755 root root -"
        "d /var/lib/openvpn 0755 root root -"
        "d /etc/openvpn 0755 root root -"
        "d /etc/openvpn/server 0755 root root -"
      ];
    })

    (lib.mkIf (cfg.enable && config.mySystem.impermanence.enable) {
      environment.persistence."/persistent" = {
        directories = [
          "/etc/openvpn/"
          "/var/lib/openvpn/"
          "/var/log/openvpn/"
        ];
      };
    })
  ];
}

/*
=== INITIAL SERVER SETUP ===

First time setup - generate server certificates and keys using Easy-RSA:

```bash
# 1. Initialize PKI
cd /etc/openvpn/server && sudo su
easyrsa init-pki

# 2. Build CA (Certificate Authority)
easyrsa build-ca nopass
# When prompted, enter a Common Name like "SkyloftVPN-CA"

# 3. Generate server certificate and key
easyrsa build-server-full server nopass

# 4. Generate Diffie-Hellman parameters (this takes a while)
easyrsa gen-dh

# 5. Generate TLS authentication key
openvpn --genkey secret ta.key

# 6. Copy files to the right location
cp pki/ca.crt /etc/openvpn/server/
cp pki/issued/server.crt /etc/openvpn/server/
cp pki/private/server.key /etc/openvpn/server/
cp pki/dh.pem /etc/openvpn/server/dh2048.pem
# ta.key should already be in /etc/openvpn/server/

# 7. Set proper permissions
chmod 600 /etc/openvpn/server/server.key
chmod 600 /etc/openvpn/server/ta.key
```

After initial setup, rebuild NixOS:
```bash
sudo nixos-rebuild switch
```

=== PORT FORWARDING ON ROUTER ===

You need to forward BOTH ports on your router:
1. UDP 1194 → Your server IP (for fast UDP connections)
2. TCP 443 → Your server IP (for restricted networks)

Most routers let you forward the same destination IP on different protocols.

=== CREATING A NEW CLIENT (WITH UDP + TCP FALLBACK) ===

For each new client, run these commands on the server. The client will automatically
try UDP first (faster) and fall back to TCP if UDP is blocked:

```bash
# 1. Navigate to Easy-RSA directory
cd /etc/openvpn/server

# 2. Generate client certificate and key (change "clientname" to your device name)
export CLIENT_NAME="hyruleCastleYeshey"  # or kakarikoYeshey, A70PhoneYeshey, etc.
easyrsa build-client-full "$CLIENT_NAME" nopass

# 3. Set server public IP
export SERVER_PUBLIC_IP="143.47.53.175"

# 4. Create client configuration file with UDP + TCP fallback
cat > "${CLIENT_NAME}.ovpn" <<'EOF'
client
dev tun
# Try UDP first (faster), then TCP (more compatible)
remote 143.47.53.175 1194 udp
remote 143.47.53.175 443 tcp

resolv-retry infinite
nobind
persist-key
persist-tun

cipher AES-256-GCM
auth SHA256
tls-version-min 1.2

remote-cert-tls server
verb 3
comp-lzo

# DNS
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1

<ca>
EOF
cat pki/ca.crt >> "${CLIENT_NAME}.ovpn"
cat >> "${CLIENT_NAME}.ovpn" <<'EOF'
</ca>

<cert>
EOF
cat pki/issued/${CLIENT_NAME}.crt >> "${CLIENT_NAME}.ovpn"
cat >> "${CLIENT_NAME}.ovpn" <<'EOF'
</cert>

<key>
EOF
cat pki/private/${CLIENT_NAME}.key >> "${CLIENT_NAME}.ovpn"
cat >> "${CLIENT_NAME}.ovpn" <<'EOF'
</key>

<tls-auth>
EOF
cat ta.key >> "${CLIENT_NAME}.ovpn"
cat >> "${CLIENT_NAME}.ovpn" <<'EOF'
</tls-auth>
key-direction 1
EOF

echo "Client configuration created: ${CLIENT_NAME}.ovpn"
echo "This config will try UDP first, then fall back to TCP if needed."
```

=== IMPORTING ON CLIENT ===

**GNOME/NetworkManager (Linux):**
1. Install OpenVPN plugin: `pkgs.networkmanager-openvpn`
2. Copy the .ovpn file to your client
3. In GNOME Settings → Network → VPN → Click '+' → Import from file
4. Select the .ovpn file and connect

**Android:**
1. Install "OpenVPN for Android" from Play Store
2. Transfer the .ovpn file to your phone
3. Open the app → '+' → Import → Select the .ovpn file

**iOS:**
1. Install "OpenVPN Connect" from App Store
2. Transfer the .ovpn file via email/cloud
3. Open with OpenVPN Connect app

=== TROUBLESHOOTING ===

Check OpenVPN server status:
```bash
# Check both UDP and TCP services
sudo systemctl status openvpn-skyloftVPN-UDP.service
sudo systemctl status openvpn-skyloftVPN-TCP.service

# View logs
sudo journalctl -u openvpn-skyloftVPN-UDP.service -f
sudo journalctl -u openvpn-skyloftVPN-TCP.service -f
```

Check connected clients:
```bash
cat /var/log/openvpn/status-udp.log
cat /var/log/openvpn/status-tcp.log
```

Test connectivity from client after connecting:
```bash
ping 10.8.0.1  # UDP server (if connected via UDP)
ping 10.8.1.1  # TCP server (if connected via TCP)
```

Check which protocol your client is using:
```bash
# On client, check OpenVPN logs or connection info
# NetworkManager: Check connection details in settings
# Android/iOS: Check app connection info
```

Test port forwarding from outside your network:
```bash
# From another network, test if ports are open:
nc -zv 143.47.53.175 1194  # Test UDP (may not work with nc)
nc -zv 143.47.53.175 443   # Test TCP
```

=== NOTES ===

- Both servers use the SAME certificates - no need to regenerate for existing clients
- UDP is faster but may be blocked; TCP on port 443 works on most restricted networks
- Clients with dual-protocol configs automatically try UDP first, then TCP
- Each protocol uses a different subnet (10.8.0.0/24 for UDP, 10.8.1.0/24 for TCP)
- Port 443 (TCP) is the standard HTTPS port, making it harder for firewalls to block
- You can keep your old .ovpn files - they'll still work with just UDP
- The new dual-protocol .ovpn files work everywhere and pick the best protocol automatically
*/
