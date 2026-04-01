{ inputs, ... }:
{
  flake.modules.nixos.gnome-minimal = {
    imports = with inputs.self.modules.nixos; [ gnome-minimal-tier ];
    home-manager.sharedModules = [ inputs.self.modules.homeManager.gnome-minimal-tier ];
  };
  flake.modules.homeManager.gnome-minimal = {
    imports = with inputs.self.modules.homeManager; [ gnome-minimal-tier ];
  };
}