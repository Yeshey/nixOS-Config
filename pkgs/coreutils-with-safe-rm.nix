{
  lib,
  pkgs,
}:

# copying normal coreutils output to prevent rebuilding coreutils (https://discourse.nixos.org/t/overriding-a-package-without-rebuilding-it/13898/7?u=yeshey)
pkgs.symlinkJoin {
  name = "coreutils-wrapped";
  paths = [ pkgs.coreutils ];
  nativeBuildInputs = [ ];
  postBuild = ''
    rm $out/bin/rm
    ln -s ${pkgs.safe-rm}/bin/safe-rm $out/bin/rm
  '';
}