{ inputs, ... }:
{
  flake.modules.nixos.gnome-base = {
    imports = with inputs.self.modules.nixos; [ gnome-base-tier ];
    home-manager.sharedModules = [ inputs.self.modules.homeManager.gnome-base-tier ];
  };
  flake.modules.homeManager.gnome-base = {
    imports = with inputs.self.modules.homeManager; [ gnome-base-tier ];
  };
}