#
#  Home-manager configuration for desktop
#
#  flake.nix
#   └─ ./hosts
#       └─ ./desktop
#           └─ home.nix *
#

{ pkgs, ... }:

{

  home = {                                # Specific packages
    packages = with pkgs; [

      gimp
      inkscape

    ];
  };

}
