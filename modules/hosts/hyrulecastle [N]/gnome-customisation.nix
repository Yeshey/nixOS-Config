{
  flake.modules.nixos.hyrulecastle = 
    { lib, config, ... }: 
    {
      config = lib.mkIf config.systemConstants.isGnome {
        services.displayManager.gdm.autoSuspend = false;
      };
    };
}