# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs,
}:

with pkgs;

rec {
  # examplepkg = callPackage ./example.nix {};
  webots = libsForQt5.callPackage ./webots.nix { };

  myOnedriver = callPackage ./onedriver-his.nix { };  

  coreutils-with-safe-rm = callPackage ./coreutils-with-safe-rm.nix { };

  muvm = callPackage ./muvm.nix { };
}
