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
    ./gnome/default.nix
    ./plasma/default.nix
    ./non-nixos.nix
    ./zsh/default.nix
    ./direnv.nix
    ./homeApps/default.nix
    ./hyprland/default.nix
    ./autoStartApps.nix
    ./onedriver.nix
    ./agenix/default.nix
    ./ssh/default.nix
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
