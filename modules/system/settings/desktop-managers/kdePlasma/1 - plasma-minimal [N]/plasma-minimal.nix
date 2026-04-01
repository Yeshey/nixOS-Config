{
  flake.modules.nixos.plasma-minimal = 
    {
      systemConstants.isKdePlasma = true;
      services = {
        desktopManager.plasma6.enable = true;
        displayManager.sddm.enable = true;
      };
      networking.networkmanager.enable = true;
    };

  flake.modules.homeManager.plasma-minimal = { };
}