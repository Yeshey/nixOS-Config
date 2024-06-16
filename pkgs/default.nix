# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs,
}:
rec {
  # example = pkgs.callPackage ./example { };
  wallpapers = pkgs.callPackage ./wallpapers { };

  myOnedriver = pkgs.callPackage ./onedriver-his.nix { };  

  # mybox86 = pkgs.callPackage ./box86.nix { };
  mybox86 =
    let
      args = {
        hello-x86_32 = if pkgs.stdenv.hostPlatform.isx86_32 then
          pkgs.hello
        else
          pkgs.pkgsCross.gnu32.hello;
      };
    in
    if pkgs.stdenv.hostPlatform.is32bit then
      pkgs.callPackage ./box86.nix args
    else if pkgs.stdenv.hostPlatform.isx86_64 then
      pkgs.pkgsCross.gnu32.callPackage ./box86.nix args
    else if pkgs.stdenv.hostPlatform.isAarch64 then
      pkgs.pkgsCross.armv7l-hf-multiplatform.callPackage ./box86.nix args
    else
      throw "Don't know 32-bit platform for cross from: ${pkgs.stdenv.hostPlatform.stdenv}";
}
