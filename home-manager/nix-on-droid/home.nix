{ pkgs
, ...
}:

{
  imports = [
    ./../../modules/home-manager
  ];

  nix.package = pkgs.nix;

  home.packages = [
    pkgs.nix
  ];

  home.stateVersion = "24.05";
}
