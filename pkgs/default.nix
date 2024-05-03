# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs ? import <nixpkgs> { },
}:
rec {
  wallpapers = pkgs.callPackage ./wallpapers { };

  myOnedriver = pkgs.callPackage ./onedriver.nix { };
  # example = pkgs.callPackage ./example { };
}
