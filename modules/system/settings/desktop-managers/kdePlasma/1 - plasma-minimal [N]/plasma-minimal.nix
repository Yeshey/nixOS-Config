{ inputs, ... }:
{
  flake.modules.nixos.plasma-minimal = {
    imports = with inputs.self.modules.nixos; [ plasma-minimal-tier ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.plasma-minimal-tier
    ];
  };
}