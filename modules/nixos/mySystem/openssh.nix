{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.openssh;
in
{
  options.mySystem.openssh = with lib; {
    enable = mkEnableOption "openssh";

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
    networking.firewall.enable = false;

  };
}
