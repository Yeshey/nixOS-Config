{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
  imports = [
    # ...
  ];

  environment.systemPackages = with pkgs; [
    (callPackage ./../../configFiles/playit-cli.nix {})
    jdk17
  ];

  # run playit-cli launch ./../main_server_config.toml
  # in here: /home/yeshey/Servers/minecraft/Valhelsia5/server
  # The address is quotes-sara.at.ply.gg:18976
  # todo make a service and add playit.cli to nixpkgs?

}
