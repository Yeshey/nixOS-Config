{ config, pkgs, user, location, lib, ... }:

{
  imports = [
    # ...
  ];

  environment.systemPackages = with pkgs; [
    (callPackage ./../../pkgs/playit-cli.nix {}) # TODO ???
    jdk17
  ];

  # run playit-cli launch ./../main_server_config.toml
  # in here: /home/yeshey/Servers/minecraft/Valhelsia5/server
  # The address is quotes-sara.at.ply.gg:18976
  # TODO make a service and add playit.cli to nixpkgs?

}
