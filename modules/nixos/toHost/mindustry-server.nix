{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.mindustry-server;
in
{
  options.toHost.mindustry-server = {
    enable = (lib.mkEnableOption "mindustry-server");
  };

  config = lib.mkIf cfg.enable {

    # had to run sudo netstat -punta to figure it out
    networking.firewall.allowedTCPPorts = [
      6567 # for mindustry hosting
      7657
    ];
    networking.firewall.allowedUDPPorts = [
      6567 # for mindustry hosting
      7657
    ];

    networking.firewall.allowedUDPPortRanges = [
      {
        from = 30000;
        to = 65535;
      }
    ];
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 47000;
        to = 65535;
      }
    ];

    environment.systemPackages = with pkgs; [
      mindustry-server
    ];

  };
}
