# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs ? import <nixpkgs> {}}: rec {
  wallpapers = pkgs.callPackage ./wallpapers {};

  # example = pkgs.callPackage ./example { };
}
