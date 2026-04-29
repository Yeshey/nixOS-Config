{ inputs, ... }:
{
  flake.modules.nixos.syncthing = {
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.syncthing
    ];

    # ports: https://docs.syncthing.net/users/firewall.html
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };

  flake.modules.homeManager.syncthing = {
    services.syncthing = {
      enable = true;
      settings.options = {
        relaysEnabled = true;
        urAccepted = 3;
      };
    };
  };
}