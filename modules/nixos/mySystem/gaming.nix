{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.gaming;
in
{
  options.mySystem.gaming = {
    enable = lib.mkEnableOption "gaming";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    environment.systemPackages = with pkgs; [ mindustry ];

    # for mindustry hosting
    /*
    networking.firewall.allowedTCPPorts = [
      6567 # for mindustry hosting
      7657
      1707
    ];
    networking.firewall.allowedUDPPorts = [
      6567 # for mindustry hosting
      7657
      1707
    ];*/
    # had to run sudo netstat -punta to figure it out, using a lot of random ports?, how aweful this is kkk
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
    # networking.firewall.enable = false;

    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
      };
      gamemode.enable = true; # allows games to request a set of optimisations be temporarily applied
    };
  };
}
