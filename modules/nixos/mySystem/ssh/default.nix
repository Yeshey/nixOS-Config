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

    openFirewall = mkEnableOption "openFirewall";
  };

  config = lib.mkIf cfg.enable {

    services.openssh = with lib; {
      enable = true;
      settings.PermitRootLogin = lib.mkDefault "yes"; # TODO no
      settings.X11Forwarding = lib.mkDefault true;
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
