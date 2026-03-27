{ pkgs, ... }:
pkgs.symlinkJoin {
  name = "coreutils-wrapped";
  paths = [ pkgs.coreutils ];
  postBuild = ''
    rm $out/bin/rm
    ln -s ${pkgs.safe-rm}/bin/safe-rm $out/bin/rm
  '';
}