{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome;
in
{
  imports = [
    ./gnome
    ./plasma
    ./non-nixos.nix
    ./zsh
    ./direnv.nix
    ./homeApps
    ./hyprland
    ./autoStartApps.nix
    ./onedriver.nix
    ./agenix
    ./ssh
    ./stylix.nix
    ./xdgPersonalFilesOrganization.nix
  ];
  options.myHome = with lib; {
    user = mkOption {
      type = types.str;
      default = "yeshey";
    };
  };
  config = {
    home = rec {
      username = lib.mkDefault cfg.user; # TODO username
      homeDirectory = lib.mkDefault "/home/${username}";
      stateVersion = lib.mkDefault "22.11";
    };
    nix.gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 14d";
      frequency = lib.mkDefault "weekly";
    };
  };
}
