{ pkgs
, ...
}:

{
  imports = [
    ./../../modules/home-manager/myHome
  ];

  myHome = {
    enable = true;
    # All the options
    user = "yeshey";
    dataStoragePath = "~/";
  };

  nix.package = pkgs.nix;

  home.packages = [
    pkgs.nix
  ];

  home.stateVersion = "24.05";
}
