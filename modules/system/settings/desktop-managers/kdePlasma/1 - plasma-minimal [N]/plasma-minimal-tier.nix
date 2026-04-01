{
  flake.modules.nixos.plasma-minimal-tier = {
    systemConstants.isKdePlasma = true;
    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.enable = true;
    networking.networkmanager.enable = true;
  };

  flake.modules.homeManager.plasma-minimal-tier = { };
}