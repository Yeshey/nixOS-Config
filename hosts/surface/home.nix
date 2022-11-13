#
#  Home-manager configuration for Surface
#
#  flake.nix
#   └─ ./hosts
#       └─ ./desktop
#           └─ home.nix *
#

{ pkgs, ... }:

{
  imports = [ ./configFiles/dconf.nix ]; # gnome configuration

  home = {                                # Specific packages
    packages = with pkgs; [
      p3x-onenote
    ];
  };

  # Raw configuration files (https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix)
  home.file.".config/user-dirs.dirs".source = ./configFiles/user-dirs.dirs; # nautilus configuration for surface
  
}
