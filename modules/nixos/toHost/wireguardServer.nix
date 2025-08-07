# check pub key cat /etc/wireguard/server.pub
# helpped by deepseek
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.toHost.wireguardServer;
  
  # Automatically generate and persist keys
  serverPrivateKeyFile = "/etc/wireguard/server.key";
  generateKeys = ''
    mkdir -p /etc/wireguard
    if [ ! -f ${serverPrivateKeyFile} ]; then
      umask 077
      ${pkgs.wireguard-tools}/bin/wg genkey > ${serverPrivateKeyFile}
    fi
  '';
in
{
  options.toHost.wireguardServer = with lib; {
    enable = mkEnableOption "wireguardServer";
  };

  config = lib.mkIf cfg.enable {
    # Key generation service
    system.activationScripts.wireguardKeys = {
      text = generateKeys;
      deps = [];
    };

    networking.firewall.allowedUDPPorts = [ 51820 ];

    networking.wireguard.interfaces.wg0 = {
      ips = [ "10.100.0.1/24" ];
      listenPort = 51820;
      
      # Use generated key
      privateKeyFile = serverPrivateKeyFile;
      
      # Automatically extract public key
      postSetup = let
        publicKeyScript = pkgs.writeScript "wg-publickey" ''
          ${pkgs.wireguard-tools}/bin/wg pubkey < ${serverPrivateKeyFile}
        '';
      in ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
        echo "Server Public Key: $(${publicKeyScript})"
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
      '';

      peers = [
        { 
          name = "Yeshey";
          publicKey = "{client public key}";
          allowedIPs = [ "10.100.0.2/32" ];
        }
      ];
    };

    environment.persistence."/persistent" = {
      directories = [ "/etc/wireguard" ];
    };
  };
}