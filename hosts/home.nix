#
#  Common Home-Manager Configuration
#

{ config, lib, pkgs, user, ... }:

{ 

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";

    packages = with pkgs; [
      github-desktop
      cmatrix
    ];
  };

  nixpkgs.config.allowUnfree = true;

  programs = {
    home-manager.enable = true;
  };

  home.stateVersion = "22.11";
}
