{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome;
  nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
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
  ];
  options.myHome = with lib; {
    user = mkOption {
      type = types.str;
      default = "yeshey";
    };
    wallpaper = mkOption {
      type = types.nullOr types.package;
      default = null;
    };
    colorScheme.setBasedOnWallpaper.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Generates a colorscheme from the wallpaper if colorScheme.theme is not set";
    };
    colorScheme.setBasedOnWallpaper.variant = mkOption {
      type = types.str;
      default = "dark";
      description = "Either \"dark\" or \"light\"";
    };
    colorScheme.theme = mkOption {
      type = types.nullOr types.attrs;
      default =
        if cfg.wallpaper == null || cfg.colorScheme.setBasedOnWallpaper.enable == false then
          null
        else
          nix-colors-lib.colorSchemeFromPicture {
            path = cfg.wallpaper;
            variant = cfg.colorScheme.setBasedOnWallpaper.variant;
          };
    };
  };
  config = {
    home = rec {
      username = lib.mkDefault cfg.user; # TODO username
      homeDirectory = lib.mkDefault "/home/${username}";
      stateVersion = lib.mkDefault "22.11";
    };
  };
}
