{ inputs, config, lib, pkgs, ... }:

let
  cfg = config.myHome;
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
      # default = pkgs.wallpapers.stellarCollisionByKuldarleement;
    };
    colorScheme = mkOption {
      type = types.attrs;
      default = inputs.nix-colors.colorSchemes.rose-pine-moon;
      #type = types.lazyAttrsOf appType;
      #default = {}; # inputs.nix-colors.colorSchemes.ocean; # by default use all
      #default = ""; # by default use all # TODO by default, nothing?
    };
  };
  config = {
    #colorscheme = cfg.colorScheme;
    #colorScheme = inputs.nix-colors.colorSchemes.${cfg.passthru};
    #colorscheme = inputs.nix-colors.colorSchemes.rose-pine-moon;
    # themes: https://github.com/tinted-theming/base16-schemes
    # colorScheme = inputs.nix-colors.colorSchemes.ocean; # black-metal-venom; # TODO add option 
  };
}
