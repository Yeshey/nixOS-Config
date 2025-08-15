{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  services.fastapi-dls = {
    enable = true;
    timezone = "Europe/Lisbon";
    listen.ip = "192.168.1.169";
  };

  # have to use v1 of fastapi dls for it to work with 17_3

  networking.firewall.allowedTCPPorts = [
    443
  ];
}