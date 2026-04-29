{
  flake.modules.nixos.skyloft = {
    networking.firewall.interfaces."tun0".allowedTCPPorts = [ 8384 ]; # allow gui through the VPN interface
  };

  flake.modules.homeManager.skyloft = {
    services.syncthing = {
      guiAddress = "0.0.0.0:8384";
    };
  };
}