{
  flake.modules.nixos.open-vpn =
    { lib, config, pkgs, ... }:
    let
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
        options.open-vpn = with lib; {
          enable = lib.mkOption { # not using rn
            type = lib.types.bool;
            default = true;
            description = "OpenVPN server (UDP + TCP, NetworkManager compatible, IPv6 enabled)";
          };
          enableSharedGuest = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Shared guest VPN (internet-only access)";
          };
        };

        config = lib.mkMerge [( lib.mkIf config.open-vpn.enableSharedGuest {
          networking.firewall.checkReversePath = "loose"; # https://claude.ai/share/4f1d42fb-e2ae-42fa-be71-045c72e17fec

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
              
              mssfix 1300
              tun-mtu 1400
              
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
              
              client-to-client

              keepalive 10 120
              persist-key
              persist-tun
              
              verb 3
              status /var/log/openvpn/status-tcp.log
              log-append /var/log/openvpn/openvpn-tcp.log
                            
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

    (lib.mkIf config.open-vpn.enableSharedGuest {
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
    })];
    };
}
      # ---------------------------------------------------------------------
      # HOW TO ADD A NEW CLIENT / GENERATE A .ovpn FILE
      # ---------------------------------------------------------------------
      # 1. On the server, generate a client key+cert pair with easyrsa
      #    (already in environment.systemPackages). From wherever your PKI
      #    dir lives (the one that produced ca.crt / server.crt / dh2048.pem):
      #
      #      easyrsa gen-req <clientName> nopass
      #      easyrsa sign-req client <clientName>
      #
      #    <clientName> should match a ccd entry if you want a static IP,
      #    e.g. "hyruleCastleYeshey", "kakarikoYeshey", "A70PhoneYeshey".
      #    If it's a brand new device and you want a static IP, add entries
      #    like the existing ones under ccd-udp/ccd-tcp (next free .13, etc).
      #
      # 2. Build the .ovpn file. Client configs must be self-contained, so
      #    embed the ca cert, client cert, client key, and ta.key inline
      #    (paths below match this module's caPath/taPath etc):
      #
      #      client
      #      dev tun
      #      remote 143.47.53.175 1194 udp
      #      remote 143.47.53.175 443 tcp
      #      resolv-retry infinite
      #      server-poll-timeout 5
      #      nobind
      #      persist-key
      #      persist-tun
      #      cipher AES-256-GCM
      #      auth SHA256
      #      tls-version-min 1.2
      #      remote-cert-tls server
      #      mssfix 1300
      #      tun-mtu 1400
      #      verb 3
      #
      #      # DNS (IPv4 + IPv6) - must match what the server pushes
      #      dhcp-option DNS 1.1.1.1
      #      dhcp-option DNS 1.0.0.1
      #      dhcp-option DNS 2606:4700:4700::1111
      #      dhcp-option DNS 2606:4700:4700::1001
      #      tun-ipv6
      #
      #      <ca>
      #      ...contents of ca.crt...
      #      </ca>
      #      <cert>
      #      ...contents of <clientName>.crt...
      #      </cert>
      #      <key>
      #      ...contents of <clientName>.key...
      #      </key>
      #      <tls-auth>
      #      ...contents of ta.key...
      #      </tls-auth>
      #      key-direction 1
      #
      # 3. GOTCHAS learned the hard way (keep these in sync between client
      #    and server or things silently break):
      #      - Do NOT use `fragment` — it must match on both ends and
      #        doesn't play well with AEAD ciphers (AES-256-GCM). Use
      #        `mssfix` + `tun-mtu` instead (server side already set to
      #        the same values above).
      #      - `cipher`, `auth`, and `tls-version-min` should match the
      #        server block exactly.
      #      - If a client needs a static IP, it needs a ccd entry on
      #        BOTH ccd-udp and ccd-tcp (different subnets), using the
      #        SAME <clientName> as the cert's CN.
      #
      # 4. Test: connect over the SAME network the server is reachable
      #    from (e.g. WiFi at home) before testing over cellular, so you
      #    can tell config bugs apart from carrier MTU/NAT issues.
      # ---------------------------------------------------------------------