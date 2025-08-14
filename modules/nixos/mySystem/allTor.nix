# routl all traffic through tor
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.allTor;
in
{
  options.mySystem.allTor = {
    enable = (lib.mkEnableOption "allTor");
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # 1. Tor itself
    services.tor = {
      enable = true;
      client.enable = true;          # Adds SOCKS ports 9050/9063
    };

    # 2. Transparent proxy for the whole system
    services.tor.transparentProxy = {
      enable      = true;            # Redirect every packet
      isolateDestAddr = true;        # One circuit per destination (optional)
      isGateway   = false;           # Set true if this box routes for others
      dnsPort     = 53;              # Tor’s DNSPort → 9053
      transPort   = 9040;            # Tor’s TransPort
    };

    # 3. (Optional) block anything that tries to bypass Tor
    networking.firewall.extraCommands = ''
      # Drop anything that reaches the OUTPUT table *after* Tor rules
      iptables  -A OUTPUT -m owner --uid-owner 0 -j DROP
      ip6tables -A OUTPUT -m owner --uid-owner 0 -j DROP
    '';
    
  };
}
