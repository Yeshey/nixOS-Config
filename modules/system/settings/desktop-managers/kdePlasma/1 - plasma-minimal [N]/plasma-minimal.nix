{
  inputs,
  lib,
  ...
}:
{
  flake.lib.mkIfPlasma =
    config: settings:
    let
      isPlasma =
        if config ? osConfig
        then config.osConfig.services.desktopManager.plasma6.enable or false
        else config.services.desktopManager.plasma6.enable or false;
    in
    lib.mkIf isPlasma settings;

  flake.modules.nixos.plasma-minimal = 
    {
      systemConstants.isKdePlasma = true;

      home-manager.sharedModules = [
        inputs.self.modules.homeManager.plasma-minimal
      ];
      services = {
        desktopManager.plasma6.enable = true;
        displayManager.sddm.enable = true;
      };
      networking.networkmanager.enable = true;
    };

  flake.modules.homeManager.plasma-minimal = { };
}