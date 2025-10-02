# Need to port forward UDP 1194
{ config, lib, pkgs, ... }:
let
  cfg = config.toHost.openVPN;
  vpnPort = 1194; # standard OpenVPN UDP port
  vpnNet = "10.8.0.0/24"; # VPN subnet
  vpnInterface = "tun0"; # OpenVPN interface name
  serverIP = "10.8.0.1"; # Server IP in VPN subnet
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
    enable = mkEnableOption "OpenVPN server (NetworkManager compatible)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # 1. OpenVPN Server Configuration
      services.openvpn.servers.skyloftVPN = {
        autoStart = true; # Set to true after completing initial setup
        config = ''
          # Server mode
          mode server
          tls-server
          
          # Protocol and port
          proto udp
          port ${toString vpnPort}
          dev ${vpnInterface}
          dev-type tun
          
          # Network configuration
          topology subnet
          server 10.8.0.0 255.255.255.0
          ifconfig-pool-persist /var/lib/openvpn/ipp.txt
          
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
          status /var/log/openvpn/status.log
          log-append /var/log/openvpn/openvpn.log
          
          # Performance
          comp-lzo
          
          # Allow client-to-client communication (optional)
          # client-to-client
          
          # User and group (drop privileges)
          user nobody
          group nogroup
        '';
      };

      # 2. Firewall configuration
      networking.firewall = {
        allowedUDPPorts = [ vpnPort ];
        trustedInterfaces = [ vpnInterface ];
      };

      # 3. NAT configuration for internet routing
      networking.nat = {
        enable = true;
        externalInterface = externalInterface;
        internalInterfaces = [ vpnInterface ];
      };

      # 4. IP forwarding
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

      # 5. Convenience packages
      environment.systemPackages = with pkgs; [
        openvpn
        easyrsa
      ];

      # 6. Create necessary directories
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

=== CREATING A NEW CLIENT ===

For each new client (laptop/phone), run these commands on the server:

```bash
# 1. Navigate to Easy-RSA directory
cd /etc/openvpn/server

# 2. Generate client certificate and key (change "clientname" to your device name)
export CLIENT_NAME="hyruleCastleYeshey"  # or kakarikoYeshey, A70PhoneYeshey, etc.
easyrsa build-client-full "$CLIENT_NAME" nopass

# 3. Set server public IP
export SERVER_PUBLIC_IP="143.47.53.175"

# 4. Create client configuration file
cat > "${CLIENT_NAME}.ovpn" <<'EOF'
client
dev tun
proto udp
remote 143.47.53.175 1194

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
sudo systemctl status openvpn-skyloftVPN.service
sudo journalctl -u openvpn-skyloftVPN.service -f
```

Check connected clients:
```bash
cat /var/log/openvpn/status.log
```

Test connectivity from client after connecting:
```bash
ping 10.8.0.1  # Should reach the VPN server
```

=== NOTES ===

- OpenVPN uses PKI (Public Key Infrastructure) unlike WireGuard's simpler key pairs
- Each client gets its own certificate, which can be revoked individually if needed
- The server automatically assigns IPs from the 10.8.0.0/24 pool
- TLS-auth adds an extra layer of security against DoS and packet replay attacks
- Client configs are portable - one .ovpn file contains everything needed
*/
