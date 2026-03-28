{
  flake.modules.nixos.appimage =
    { pkgs, ... }:
    {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };

      environment.systemPackages = [
        (pkgs.appimage-run.override {
          extraPkgs = p: [ p.xorg.libxshmfence ];
        })
      ];
    };
}