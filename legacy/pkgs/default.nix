# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs,
}:

with pkgs;

rec {
  # examplepkg = callPackage ./example.nix {};

  coreutils-with-safe-rm = callPackage ./coreutils-with-safe-rm.nix { };

  looking-glass-host = callPackage ./looking-glass-host.nix { };
}
