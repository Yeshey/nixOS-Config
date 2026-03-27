{
  flake.modules.nixos.hyrulecastle = 
    { lib, config, ... }: 
    let
      isGnome = config.services.desktopManager.gnome.enable or false;
    in
    {
      config = lib.mkIf isGnome {
        services.displayManager.gdm.autoSuspend = false;
      };
    };
}