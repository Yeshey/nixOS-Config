{ inputs, ... }:
{
  flake.modules.nixos.nixos-minimal = {
    imports = with inputs.self.modules.nixos; [ system-minimal-tier ];
    home-manager.sharedModules = [ inputs.self.modules.homeManager.system-minimal-tier ];
  };
  flake.modules.homeManager.nixos-minimal = {
    imports = with inputs.self.modules.homeManager; [ system-minimal-tier ];
  };
}