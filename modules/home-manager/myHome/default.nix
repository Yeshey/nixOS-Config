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
    ./cli.nix
    ./devops.nix
    ./gnome
    ./plasma
    ./neovim
    ./non-nixos.nix
    ./tmux.nix
    ./zsh
    ./homeapps.nix # TODO not okay
    ./vscodium # TODO not rly okay
    ./discord.nix # TODO not rly okay
    ./kitty.nix # TODO not rly okay
    ./alacritty.nix
  ];
  options.myHome = with lib; {
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
        if cfg.wallpaper == null || cfg.setBasedOnWallpaper == false then
          null
        else
          nix-colors-lib.colorSchemeFromPicture {
            path = cfg.wallpaper;
            variant = cfg.colorScheme.variant;
          };
    };
  };
  config = {

  };
}