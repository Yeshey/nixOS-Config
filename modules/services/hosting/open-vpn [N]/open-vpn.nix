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
          enable = mkEnableOption "OpenVPN server (UDP + TCP, NetworkManager compatible, IPv6 enabled)";
          enableSharedGuest = mkEnableOption "Shared guest VPN (internet-only access)";
        };

        config = lib.mkMerge [({
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
    })];
    };
}