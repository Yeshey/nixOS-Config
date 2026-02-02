{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.ssh;
in
{
  options.mySystem.ssh = with lib; {
    enable = mkEnableOption "ssh";

    #openFirewall = mkEnableOption "openFirewall";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    services.openssh = with lib; {
      enable = true;
      #settings.PermitRootLogin = lib.mkOverride 1010 "yes"; # TODO no
      settings = {
        # This allows a new tunnel to take over the port if the old one is stale
        StreamLocalBindUnlink = "yes"; 
        
        # If you want to connect to the tunnel from OUTSIDE the server 
        # (e.g., from your laptop to the server's IP:2232), you need this:
        GatewayPorts = "clientspecified"; 
        
        X11Forwarding = lib.mkOverride 1010 true;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 3;
      };
      # settings.AllowUsers = [ "root" ];
    };
    # security.sudo.wheelNeedsPassword = false; # TODO remove (how do you do secrets management)
    # security.pam.enableSSHAgentAuth = true;

    #networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 22 ];
    # networking.firewall.enable = false;

    programs.ssh = {
      # startAgent = true;
      forwardX11 = true;
      extraConfig = builtins.readFile ./config; # puts in /etc/ssh/ssh_config that goes for everyone
    };

  };
}
