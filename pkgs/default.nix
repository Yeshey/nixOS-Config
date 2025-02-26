# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs,
}:

with pkgs;

rec {
  # example = pkgs.callPackage ./example { };
  wallpapers = callPackage ./wallpapers { };

  myOnedriver = callPackage ./onedriver-his.nix { };  

  coreutils-with-safe-rm = callPackage ./coreutils-with-safe-rm.nix { };

  my-webots = callPackage ./webots.nix { };

  mybox86 =
    let
      args = {
        hello-x86_32 = if stdenv.hostPlatform.isx86_32 then
          hello
        else
          pkgsCross.gnu32.hello;
      };
    in
    if stdenv.hostPlatform.is32bit then
      callPackage ./box86.nix args
    else if stdenv.hostPlatform.isx86_64 then
      pkgsCross.gnu32.callPackage ./box86.nix args
    else if stdenv.hostPlatform.isAarch64 then
      pkgsCross.armv7l-hf-multiplatform.callPackage ./box86.nix args
    else
      throw "Don't know 32-bit platform for cross from: ${stdenv.hostPlatform.stdenv}";
}
