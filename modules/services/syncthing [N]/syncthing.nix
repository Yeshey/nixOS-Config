{ inputs, ... }:
{
  flake.modules.nixos.syncthing = {
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.syncthing
    ];

    # ports: https://docs.syncthing.net/users/firewall.html
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
    networking.firewall.interfaces."tun0".allowedTCPPorts = [ 8384 ]; # allow gui through the VPN interface
  };

  flake.modules.homeManager.syncthing = {
    services.syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
      settings.options = {
        relaysEnabled = true;
        urAccepted = 3;
      };
    };
  };
}