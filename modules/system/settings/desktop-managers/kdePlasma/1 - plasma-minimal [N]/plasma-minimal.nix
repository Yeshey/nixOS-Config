{
  inputs,
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
    if isPlasma then settings else { };

  flake.modules.nixos.plasma-minimal = 
    {
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