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
    wallpaper = mkOption {
      type = types.package;
      default = 
      builtins.fetchurl {
        url = "https://images6.alphacoders.com/655/655990.jpg";
        sha256 = "b09b411a9c7fc7dc5be312ca9e4e4b8ee354358daa792381f207c9f4946d95fe";
      };
      /*
      builtins.fetchurl {
        url = "https://cdna.artstation.com/p/assets/images/images/018/711/480/large/john-kearney-cityscape-poster-artstation-update.jpg";
        sha256 = "sha256:1a2krq61502z5zka0a97zll4s8x9dv2qaap5hivpr7fpzl46qp2n";
      }; */ 
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
