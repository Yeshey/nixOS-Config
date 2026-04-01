{ inputs, ... }:
{
  flake.modules.nixos.plasma-full = {
    imports = with inputs.self.modules.nixos; [ plasma-full-tier ];
    home-manager.sharedModules = [ inputs.self.modules.homeManager.plasma-full-tier ];
  };
  flake.modules.homeManager.plasma-full = {
    imports = with inputs.self.modules.homeManager; [ plasma-full-tier ];
  };
}