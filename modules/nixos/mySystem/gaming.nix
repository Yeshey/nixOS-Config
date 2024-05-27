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

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ mindustry ];

    /*
    networking.firewall.allowedTCPPorts = [
      6567 # for mindustry hosting
    ];
    networking.firewall.allowedUDPPorts = [
      6567 # for mindustry hosting
    ];*/
    networking.firewall.enable = false; # TODO, the fuck, what ports do I need t open

    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
      };
      gamemode.enable = true; # allows games to request a set of optimisations be temporarily applied
    };
  };
}
