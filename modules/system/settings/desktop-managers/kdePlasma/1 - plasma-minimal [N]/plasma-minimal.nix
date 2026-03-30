{
  inputs,
  ...
}:
{
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