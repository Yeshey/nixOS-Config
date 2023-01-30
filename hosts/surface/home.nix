#
#  Home-manager configuration for Surface
#
#  flake.nix
#   └─ ./hosts
#       └─ ./desktop
#           └─ home.nix *
#

{ pkgs, ... }:

rec { 
  imports = [ ./configFiles/dconf.nix ]; # gnome configuration
  # Generated with: nix-shell -p dconf2nix --command "dconf dump / | dconf2nix -e --timeout 15 --verbose > dconf.nix"

  home = {                                # Specific packages
    packages = with pkgs; [
      psensor
      s-tui

      # For gnome
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.burn-my-windows
      gnomeExtensions.hibernate-status-button
      gnomeExtensions.tray-icons-reloaded
    ];
  };

  # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
  home.file.".config/user-dirs.dirs".source = ./configFiles/user-dirs.dirs; # nautilus configuration for surface
  
}
