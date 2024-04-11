{ inputs, config, lib, pkgs, ... }:

let
  cfg = config.myHome;
in
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
    ./cli.nix
    ./devops.nix
    ./gnome
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
    colorScheme = mkOption {
      #type = types.listOf types.str;
      default = inputs.nix-colors.colorSchemes.ocean; # by default use all
      #default = ""; # by default use all # TODO by default, nothing?
    };
  };
  config = {
    colorScheme = cfg.colorScheme;
    # themes: https://github.com/tinted-theming/base16-schemes
    # colorScheme = inputs.nix-colors.colorSchemes.ocean; # black-metal-venom; # TODO add option 
  };
}
