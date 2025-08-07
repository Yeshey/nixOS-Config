# check pub key cat /etc/wireguard/client.pub
# helpped by deepseek
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.wireguardClient;
  
  clientPrivateKeyFile = "/etc/wireguard/client.key";
  generateKeys = ''
    mkdir -p /etc/wireguard
    if [ ! -f ${clientPrivateKeyFile} ]; then
      umask 077
      ${pkgs.wireguard-tools}/bin/wg genkey > ${clientPrivateKeyFile}
    fi

    # Generate public key if it doesn't exist
    if [ ! -f /etc/wireguard/client.pub ]; then
      ${pkgs.wireguard-tools}/bin/wg pubkey < ${clientPrivateKeyFile} > /etc/wireguard/client.pub
    fi
  '';
in
{
  options.mySystem.wireguardClient = with lib; {
    enable = mkEnableOption "wireguardClient";
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.wireguardKeys = {
      text = generateKeys;
      deps = [];
    };

    networking.wireguard.interfaces.wg0 = {
      ips = [ "10.100.0.2/24" ];
      privateKeyFile = clientPrivateKeyFile;

      peers = [
        {
          publicKey = "tFnVEEbaOZu4qW+SigRWx9cyaYuhl03M0+MLUYsgZ2I="; # server public key
          allowedIPs = [ "10.100.0.1/32" ];
          endpoint = "143.47.53.175:51820";
          persistentKeepalive = 25;
        }
      ];
    };

    environment.persistence."/persistent" = {
      directories = [ "/etc/wireguard" ];
    };
  };
}