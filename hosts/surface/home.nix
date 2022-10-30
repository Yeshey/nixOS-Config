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

  home = {                                # Specific packages
    packages = with pkgs; [
      p3x-onenote
      psensor
    ];
  };

}
