{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.minecraft;
in
{
  options.toHost.minecraft = {
    enable = (lib.mkEnableOption "minecraft");
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      (callPackage ./../../pkgs/playit-cli.nix { }) # TODO ???
      jdk17
    ];

    # run playit-cli launch ./../main_server_config.toml
    # in here: /home/yeshey/PersonalFiles/Servers/minecraft/Valhelsia5/server
    # The address is quotes-sara.at.ply.gg:18976
    # TODO make a service and add playit.cli to nixpkgs?
  };
}
