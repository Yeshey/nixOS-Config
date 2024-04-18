{ inputs, config, lib, pkgs, ... }:

let
  cfg = config.mySystem.gaming;
in
{
  options.mySystem.gaming = {
    enable = lib.mkEnableOption "gaming";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ 
      inputs.nix-gaming.packages.${pkgs.system}.osu-stable
    ];
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
      };
      gamemode.enable = true; # allows games to request a set of optimisations be temporarily applied
    };
  };
}
