{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
  imports = [
    # ...
  ];

  environment.systemPackages = with pkgs; [
    (callPackage ./../../configFiles/playit-cli.nix {})
  ];

}
