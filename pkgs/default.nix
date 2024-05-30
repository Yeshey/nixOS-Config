# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs ? import <nixpkgs> { },
}:
rec {
  wallpapers = pkgs.callPackage ./wallpapers { };

  myOnedriver = pkgs.callPackage ./onedriver-his.nix { };
  # example = pkgs.callPackage ./example { };

  mybox86 = pkgs.callPackage ./box86.nix { };
}
