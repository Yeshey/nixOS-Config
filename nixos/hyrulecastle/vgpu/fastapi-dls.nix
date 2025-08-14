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
  };
}