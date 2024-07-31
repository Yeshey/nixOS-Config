{ pkgs
, ...
}:

{
  imports = [
    ./../../modules/home-manager/myHome
  ];

  nix.package = pkgs.nix;

  home.packages = [
    pkgs.nix
  ];

  home.stateVersion = "24.05";
}
