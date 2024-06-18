{ pkgs }:

pkgs.coreutils.overrideAttrs (oldAttrs: rec {
  postInstall = ''
    mv $out/bin/rm $out/bin/rm.bak
    ln -s ${pkgs.rmtrash}/bin/rmtrash $out/bin/rm
  '';
})