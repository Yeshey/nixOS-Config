{
  flake.modules.nixos.upgrade =
    { config, ... }:
    {
      system.autoUpgrade = {
        enable      = true;
        flake       = "github:yeshey/nixos-config#${config.networking.hostName}";
        flags       = [
          "--update-input" "nixpkgs"
          "--no-write-lock-file"
          "-L"                        # print build logs
        ];
        dates       = "weekly";
        allowReboot = false;          # set to true on servers that can reboot unattended
      };
    };
  
  # for Standalone HM
  # `flakeDir` defaults to ~/.config/home-manager (the HM convention). Override it if you need
  flake.modules.homeManager.upgrade =
    { ... }:
    {
      services.home-manager.autoUpgrade = {
        enable    = true;
        frequency = "weekly";
        useFlake  = true;
        # flakeDir defaults to ${config.xdg.configHome}/home-manager
      };
    };
}