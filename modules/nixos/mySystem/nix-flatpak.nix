{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.mySystem.nix-flatpak;
in
{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  options.mySystem.nix-flatpak = with lib; {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "flatpaks-nix are enabled, and auto updates as well";
    };
  };

  config = { 
    services.flatpak.update.auto = {
      enable = true;
      onCalendar = "weekly"; # Default value
    };
  };
}
