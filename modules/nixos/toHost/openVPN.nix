# Need to port forward:
# - UDP 1194 (for UDP connections)
# - UDP 1195 (for UDP connections to guest ovpns)
# - TCP 443 (for TCP connections - uses HTTPS port to bypass firewalls)

{ config, lib, pkgs, ... }:
let
  cfg = config.toHost.openVPN;
  vpnPortUDP = 1194;
  vpnPortTCP = 443;
  vpnNetUDP = "10.8.0.0/24";
  vpnNetTCP = "10.8.1.0/24";
  # IPv6 subnets - using unique local addresses (ULA)
  vpnNet6UDP = "fd00:8:0::/64";
  vpnNet6TCP = "fd00:8:1::/64";
  vpnInterfaceUDP = "tun0";
  vpnInterfaceTCP = "tun1";
  serverIPUDP = "10.8.0.1";
  serverIPTCP = "10.8.1.1";
  serverIP6UDP = "fd00:8:0::1";
  serverIP6TCP = "fd00:8:1::1";
  
  guestPortUDP = 1195;
  guestPortTCP = 8443;
  guestNetUDP = "10.8.2.0/24";
  guestNetTCP = "10.8.3.0/24";
  guestNet6UDP = "fd00:8:2::/64";
  guestNet6TCP = "fd00:8:3::/64";
  guestInterfaceUDP = "tun2";
  guestInterfaceTCP = "tun3";

  externalInterface = "enp0s6";

  serverKeyDir = "/etc/openvpn/server";
  caPath = "${serverKeyDir}/ca.crt";
  certPath = "${serverKeyDir}/server.crt";
  keyPath = "${serverKeyDir}/server.key";
  dhPath = "${serverKeyDir}/dh2048.pem";
  taPath = "${serverKeyDir}/ta.key";
  
  ccdDirUDP = "/etc/openvpn/ccd-udp";
  ccdDirTCP = "/etc/openvpn/ccd-tcp";
in
{
  options.toHost.openVPN = with lib; {
    enable = mkEnableOption "OpenVPN server (UDP + TCP, NetworkManager compatible, IPv6 enabled)";
    enableSharedGuest = mkEnableOption "Shared guest VPN (internet-only access)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # 1. OpenVPN UDP Server Configuration (IPv4 + IPv6)
      services.openvpn.servers.skyloftVPN-UDP = {
        autoStart = true;
        config = ''
          mode server
          tls-server
          
          proto udp
          port ${toString vpnPortUDP}
          dev ${vpnInterfaceUDP}
          dev-type tun
          
          # IPv4 configuration
          topology subnet
          server 10.8.0.0 255.255.255.0
          ifconfig-pool-persist /var/lib/openvpn/ipp-udp.txt
          
          # IPv6 configuration
          server-ipv6 fd00:8:0::/64
          
          client-config-dir ${ccdDirUDP}
          
          ca ${caPath}
          cert ${certPath}
          key ${keyPath}
          dh ${dhPath}
          tls-auth ${taPath} 0
          
          cipher AES-256-GCM
          auth SHA256
          tls-version-min 1.2
          
          # IPv4 routes and gateway
          push "redirect-gateway def1 bypass-dhcp"
          push "route 10.8.0.0 255.255.255.0"
          push "route 10.8.1.0 255.255.255.0"
          
          # IPv6 routes and gateway
          push "route-ipv6 2000::/3"
          push "route-ipv6 fd00:8:0::/64"
          push "route-ipv6 fd00:8:1::/64"
          
          # DNS servers (IPv4 + IPv6)
          push "dhcp-option DNS 1.1.1.1"
          push "dhcp-option DNS 1.0.0.1"
          push "dhcp-option DNS 2606:4700:4700::1111"
          push "dhcp-option DNS 2606:4700:4700::1001"
          
          client-to-client
          
          keepalive 10 120
          persist-key
          persist-tun
          
          verb 3
          status /var/log/openvpn/status-udp.log
          log-append /var/log/openvpn/openvpn-udp.log
          
          comp-lzo
          
          user nobody
          group nogroup
        '';
      };

      # 2. OpenVPN TCP Server Configuration (IPv4 + IPv6)
      services.openvpn.servers.skyloftVPN-TCP = {
        autoStart = true;
        config = ''
          mode server
          tls-server
          
          proto tcp-server
          port ${toString vpnPortTCP}
          dev ${vpnInterfaceTCP}
          dev-type tun
          
          # IPv4 configuration
          topology subnet
          server 10.8.1.0 255.255.255.0
          ifconfig-pool-persist /var/lib/openvpn/ipp-tcp.txt
          
          # IPv6 configuration
          server-ipv6 fd00:8:1::/64
          
          client-config-dir ${ccdDirTCP}
          
          ca ${caPath}
          cert ${certPath}
          key ${keyPath}
          dh ${dhPath}
          tls-auth ${taPath} 0
          
          cipher AES-256-GCM
          auth SHA256
          tls-version-min 1.2
          
          # IPv4 routes and gateway
          push "redirect-gateway def1 bypass-dhcp"
          push "route 10.8.1.0 255.255.255.0"
          push "route 10.8.0.0 255.255.255.0"
          
          # IPv6 routes and gateway
          push "route-ipv6 2000::/3"
          push "route-ipv6 fd00:8:1::/64"
          push "route-ipv6 fd00:8:0::/64"
          
          # DNS servers (IPv4 + IPv6)
          push "dhcp-option DNS 1.1.1.1"
          push "dhcp-option DNS 1.0.0.1"
          push "dhcp-option DNS 2606:4700:4700::1111"
          push "dhcp-option DNS 2606:4700:4700::1001"
          
          keepalive 10 120
          persist-key
          persist-tun
          
          verb 3
          status /var/log/openvpn/status-tcp.log
          log-append /var/log/openvpn/openvpn-tcp.log
          
          comp-lzo
          
          user nobody
          group nogroup
        '';
      };

      networking.firewall = {
        allowedUDPPorts = [ vpnPortUDP ];
        allowedTCPPorts = [ vpnPortTCP ];
        trustedInterfaces = [ vpnInterfaceUDP vpnInterfaceTCP ];
        
        extraCommands = ''
          # IPv4 NAT rules
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${vpnNetUDP} -o ${externalInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${vpnNetTCP} -o ${externalInterface} -j MASQUERADE
          
          # IPv6 NAT rules
          ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s ${vpnNet6UDP} -o ${externalInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s ${vpnNet6TCP} -o ${externalInterface} -j MASQUERADE
          
          # Cross-TUN forwarding (IPv4)
          ${pkgs.iptables}/bin/iptables -A FORWARD -i ${vpnInterfaceUDP} -o ${vpnInterfaceTCP} -j ACCEPT
          ${pkgs.iptables}/bin/iptables -A FORWARD -i ${vpnInterfaceTCP} -o ${vpnInterfaceUDP} -j ACCEPT
          
          # Cross-TUN forwarding (IPv6)
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -i ${vpnInterfaceUDP} -o ${vpnInterfaceTCP} -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -i ${vpnInterfaceTCP} -o ${vpnInterfaceUDP} -j ACCEPT
        '';
      };

      networking.nat = {
        enable = true;
        externalInterface = externalInterface;
        internalInterfaces = [ vpnInterfaceUDP vpnInterfaceTCP ];
      };

      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

      environment.systemPackages = with pkgs; [
        openvpn
        easyrsa
      ];

      systemd.tmpfiles.rules = [
        "d /var/log/openvpn 0755 root root -"
        "d /var/lib/openvpn 0755 root root -"
        "d /etc/openvpn 0755 root root -"
        "d /etc/openvpn/server 0755 root root -"
        "d ${ccdDirUDP} 0755 root root -"
        "d ${ccdDirTCP} 0755 root root -"
      ];
      
      # Static IPs - UDP
      environment.etc."openvpn/ccd-udp/hyruleCastleYeshey".text = ''
        ifconfig-push 10.8.0.10 255.255.255.0
        ifconfig-ipv6-push fd00:8:0::10/64
      '';
      
      environment.etc."openvpn/ccd-udp/kakarikoYeshey".text = ''
        ifconfig-push 10.8.0.11 255.255.255.0
        ifconfig-ipv6-push fd00:8:0::11/64
      '';
      
      environment.etc."openvpn/ccd-udp/A70PhoneYeshey".text = ''
        ifconfig-push 10.8.0.12 255.255.255.0
        ifconfig-ipv6-push fd00:8:0::12/64
      '';
      
      # Static IPs - TCP
      environment.etc."openvpn/ccd-tcp/hyruleCastleYeshey".text = ''
        ifconfig-push 10.8.1.10 255.255.255.0
        ifconfig-ipv6-push fd00:8:1::10/64
      '';
      
      environment.etc."openvpn/ccd-tcp/kakarikoYeshey".text = ''
        ifconfig-push 10.8.1.11 255.255.255.0
        ifconfig-ipv6-push fd00:8:1::11/64
      '';
      
      environment.etc."openvpn/ccd-tcp/A70PhoneYeshey".text = ''
        ifconfig-push 10.8.1.12 255.255.255.0
        ifconfig-ipv6-push fd00:8:1::12/64
      '';
    })

    (lib.mkIf (cfg.enable && cfg.enableSharedGuest) {
      services.openvpn.servers.guest-UDP = {
        autoStart = true;
        config = ''
          mode server
          tls-server
          
          proto udp
          port ${toString guestPortUDP}
          dev ${guestInterfaceUDP}
          dev-type tun
          
          topology subnet
          server 10.8.2.0 255.255.255.0
          ifconfig-pool-persist /var/lib/openvpn/ipp-guest-udp.txt
          server-ipv6 fd00:8:2::/64
          
          ca ${caPath}
          cert ${certPath}
          key ${keyPath}
          dh ${dhPath}
          tls-auth ${taPath} 0
          
          cipher AES-256-GCM
          auth SHA256
          tls-version-min 1.2
          
          duplicate-cn
          
          push "redirect-gateway def1 bypass-dhcp"
          push "route-ipv6 2000::/3"
          
          push "dhcp-option DNS 1.1.1.1"
          push "dhcp-option DNS 1.0.0.1"
          push "dhcp-option DNS 2606:4700:4700::1111"
          push "dhcp-option DNS 2606:4700:4700::1001"
          
          keepalive 10 120
          persist-key
          persist-tun
          
          verb 3
          status /var/log/openvpn/status-guest-udp.log
          log-append /var/log/openvpn/openvpn-guest-udp.log
          
          comp-lzo
          
          user nobody
          group nogroup
        '';
      };

      services.openvpn.servers.guest-TCP = {
        autoStart = true;
        config = ''
          mode server
          tls-server
          
          proto tcp-server
          port ${toString guestPortTCP}
          dev ${guestInterfaceTCP}
          dev-type tun
          
          topology subnet
          server 10.8.3.0 255.255.255.0
          ifconfig-pool-persist /var/lib/openvpn/ipp-guest-tcp.txt
          server-ipv6 fd00:8:3::/64
          
          ca ${caPath}
          cert ${certPath}
          key ${keyPath}
          dh ${dhPath}
          tls-auth ${taPath} 0
          
          cipher AES-256-GCM
          auth SHA256
          tls-version-min 1.2
          
          duplicate-cn
          
          push "redirect-gateway def1 bypass-dhcp"
          push "route-ipv6 2000::/3"
          
          push "dhcp-option DNS 1.1.1.1"
          push "dhcp-option DNS 1.0.0.1"
          push "dhcp-option DNS 2606:4700:4700::1111"
          push "dhcp-option DNS 2606:4700:4700::1001"
          
          keepalive 10 120
          persist-key
          persist-tun
          
          verb 3
          status /var/log/openvpn/status-guest-tcp.log
          log-append /var/log/openvpn/openvpn-guest-tcp.log
          
          comp-lzo
          
          user nobody
          group nogroup
        '';
      };

      networking.firewall = {
        allowedUDPPorts = [ vpnPortUDP guestPortUDP ];
        allowedTCPPorts = [ vpnPortTCP guestPortTCP ];
        trustedInterfaces = [ vpnInterfaceUDP vpnInterfaceTCP guestInterfaceUDP guestInterfaceTCP ];
        
        extraCommands = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${vpnNetUDP} -o ${externalInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${vpnNetTCP} -o ${externalInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${guestNetUDP} -o ${externalInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${guestNetTCP} -o ${externalInterface} -j MASQUERADE
          
          ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s ${vpnNet6UDP} -o ${externalInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s ${vpnNet6TCP} -o ${externalInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s ${guestNet6UDP} -o ${externalInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s ${guestNet6TCP} -o ${externalInterface} -j MASQUERADE
          
          ${pkgs.iptables}/bin/iptables -A FORWARD -i ${vpnInterfaceUDP} -o ${vpnInterfaceTCP} -j ACCEPT
          ${pkgs.iptables}/bin/iptables -A FORWARD -i ${vpnInterfaceTCP} -o ${vpnInterfaceUDP} -j ACCEPT
          
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -i ${vpnInterfaceUDP} -o ${vpnInterfaceTCP} -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -i ${vpnInterfaceTCP} -o ${vpnInterfaceUDP} -j ACCEPT
          
          ${pkgs.iptables}/bin/iptables -A FORWARD -s ${guestNetUDP} -d ${vpnNetUDP} -j REJECT
          ${pkgs.iptables}/bin/iptables -A FORWARD -s ${guestNetUDP} -d ${vpnNetTCP} -j REJECT
          ${pkgs.iptables}/bin/iptables -A FORWARD -s ${guestNetTCP} -d ${vpnNetUDP} -j REJECT
          ${pkgs.iptables}/bin/iptables -A FORWARD -s ${guestNetTCP} -d ${vpnNetTCP} -j REJECT
          
          ${pkgs.iptables}/bin/iptables -A INPUT -s ${guestNetUDP} -p tcp -j REJECT
          ${pkgs.iptables}/bin/iptables -A INPUT -s ${guestNetUDP} -p udp ! --dport 53 -j REJECT
          ${pkgs.iptables}/bin/iptables -A INPUT -s ${guestNetTCP} -p tcp -j REJECT
          ${pkgs.iptables}/bin/iptables -A INPUT -s ${guestNetTCP} -p udp ! --dport 53 -j REJECT
          
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -s ${guestNet6UDP} -d ${vpnNet6UDP} -j REJECT
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -s ${guestNet6UDP} -d ${vpnNet6TCP} -j REJECT
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -s ${guestNet6TCP} -d ${vpnNet6UDP} -j REJECT
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -s ${guestNet6TCP} -d ${vpnNet6TCP} -j REJECT
        '';
      };

      networking.nat = {
        enable = true;
        externalInterface = externalInterface;
        internalInterfaces = [ vpnInterfaceUDP vpnInterfaceTCP guestInterfaceUDP guestInterfaceTCP ];
      };
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
cat > "${CLIENT_NAME}.ovpn" <<EOF
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

# DNS (IPv4 + IPv6)
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1
dhcp-option DNS 2606:4700:4700::1111
dhcp-option DNS 2606:4700:4700::1001

# Enable IPv6
tun-ipv6

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
- Use this to delete everything from a certain client:
rm -f pki/reqs/${CLIENT_NAME}.req
rm -f pki/private/${CLIENT_NAME}.key
rm -f pki/issued/${CLIENT_NAME}.crt
*/

/*
Generate guest config:

```
# 1. Navigate to Easy-RSA directory
cd /etc/openvpn/server

# 2. Generate the shared guest certificate
export CLIENT_NAME="shared-guest"
easyrsa build-client-full "$CLIENT_NAME" nopass

# 3. Set server public IP
export SERVER_PUBLIC_IP="143.47.53.175"

# 4. Create guest configuration file with UDP + TCP fallback
cat > "${CLIENT_NAME}.ovpn" <<EOF
client
dev tun
# Try UDP first (faster), then TCP (more compatible)
remote ${SERVER_PUBLIC_IP} 1195 udp
remote ${SERVER_PUBLIC_IP} 8443 tcp

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

# DNS (IPv4 + IPv6)
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1
dhcp-option DNS 2606:4700:4700::1111
dhcp-option DNS 2606:4700:4700::1001

# Enable IPv6
tun-ipv6

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

echo "Guest configuration created: ${CLIENT_NAME}.ovpn"
echo "This file can be shared with multiple people."
echo "They will have internet access only, no access to your server services."
```

*/
