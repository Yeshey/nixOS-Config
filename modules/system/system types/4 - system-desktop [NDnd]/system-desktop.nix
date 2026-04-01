{
  inputs,
  ...
}:
{
  # seperate module to prevent HM configs being imported multiple times
  flake.modules.nixos.system-desktop = {
    imports = with inputs.self.modules.nixos; [
      system-desktop-tier
    ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.system-desktop-tier
    ];
  };
  flake.modules.homeManager.system-desktop = {
    imports = with inputs.self.modules.homeManager; [
      system-desktop-tier
    ];
  };
}
