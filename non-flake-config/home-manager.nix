# Installed Home-Manager as a Module, if I wanted each user to have access to their home manager files, I should install the standalone version
{ config, pkgs, ... }:
let
  user="yeshey";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports = [
    (import "${home-manager}/nixos")
  ];

  # Attempt at making home manager work
  home-manager.users.${user} = { pkgs, ... }: {
    home.stateVersion = "22.11";
    home.packages = with pkgs; [ 
      github-desktop
    ];
  };
  home-manager.useUserPackages = true;
}