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

     systemd.services.sshd = { # run this script before starting sshd 
      preStart = '' 
  if [ ! -f /etc/ssh/sshd_config ]; then 
    install -m600 /dev/null /etc/ssh/sshd_config 
  fi 
''; 
     };

    services.openssh = with lib; {
      enable = true;
      #settings.PermitRootLogin = lib.mkOverride 1010 "yes"; # TODO no
      settings.X11Forwarding = lib.mkOverride 1010 true;
      # settings.AllowUsers = [ "root" ];
    };
    # security.sudo.wheelNeedsPassword = false; # TODO remove (how do you do secrets management)
    # security.pam.enableSSHAgentAuth = true;

    #networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 22 ];
    # networking.firewall.enable = false;

    programs.ssh = {
      startAgent = true;
      forwardX11 = true;
      extraConfig = builtins.readFile ./config; # puts in /etc/ssh/ssh_config that goes for everyone
    };

  };
}
