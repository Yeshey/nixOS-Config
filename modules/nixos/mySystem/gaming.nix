{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.gaming;
in
{
  options.mySystem.gaming = {
    enable = lib.mkEnableOption "gaming";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ lutris protonup-ng ];
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
      };
      gamemode.enable = true; # allows games to request a set of optimisations be temporarily applied
      # corectrl = {
      #   enable = true;
      #   gpuOverclock.enable = true;
      # };
    };
  };
}
