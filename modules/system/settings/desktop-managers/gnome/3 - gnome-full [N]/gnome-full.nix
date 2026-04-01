{ inputs, ... }:
{
  flake.modules.nixos.gnome-full = {
    imports = with inputs.self.modules.nixos; [ gnome-full-tier ];
    home-manager.sharedModules = [ inputs.self.modules.homeManager.gnome-full-tier ];
  };
  flake.modules.homeManager.gnome-full = {
    imports = with inputs.self.modules.homeManager; [ gnome-full-tier ];
  };
}