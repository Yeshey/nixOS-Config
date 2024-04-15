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
    # need rec (recursive) to use wallpaper variable in colorScheme
    wallpaper = mkOption {
      type = types.nullOr types.package;
      default = null;
      # default = pkgs.wallpapers.stellarCollisionByKuldarleement;
    };
    /*
      wallpaper = mkOption {
        type = types.package;
        # default = null;
        default = pkgs.wallpapers.stellarCollisionByKuldarleement;
      };
    */
    colorScheme = mkOption {
      type = types.nullOr types.attrs;
      default =
        if cfg.wallpaper == null then
          null
        else
          nix-colors-lib.colorSchemeFromPicture {
            path = cfg.wallpaper;
            variant = "dark"; # TODO expose this option
          }; # TODO expose option so you can have a wallpaper without it stating the theme
      #default = nix-colors-lib.colorSchemeFromPicture {
      #  path = cfg.wallpaper; #  mkIfElse ( wallpaper != null ) pkgs.wallpapers.stellarCollisionByKuldarleement pkgs.wallpapers.nierAutomataWallpaper;
      #  variant = "dark"; # TODO expose this option
      #};

      # mkIfElse ( wallpaper != null ) pkgs.wallpapers.stellarCollisionByKuldarleement pkgs.wallpapers.nierAutomataWallpaper;
      #default = nix-colors-lib.colorSchemeFromPicture {
      #  path = pkgs.wallpapers.stellarCollisionByKuldarleement;
      #wallpaper.path; # ./../../../pkgs/wallpapers/StellarCollisionByKuldarLeement.jpg;
      #  variant = "dark"; # TODO expose this option
      #};
      # default = inputs.nix-colors.colorSchemes.rose-pine-moon;
      #  lib.mkIf ( wallpaper != null )
    };

    #nix-colors-lib.colorSchemeFromPicture {
    #  path = ./../../../pkgs/wallpapers/StellarCollisionByKuldarLeement.jpg;
    #  variant = "light";
    #};
    #wallpaper;
    /*
      mkOption {
        type = types.attrs;
        default = inputs.nix-colors.colorSchemes.rose-pine-moon;
        #type = types.lazyAttrsOf appType;
        #default = {}; # inputs.nix-colors.colorSchemes.ocean; # by default use all
        #default = ""; # by default use all # TODO by default, nothing?
      };
    */
  };
  config = {
    #config.colorScheme = inputs.nix-colors.colorSchemes.rose-pine-moon;
    # cfg.colorScheme = pkgs.wallpapers.stellarCollisionByKuldarleement;
    #colorscheme = cfg.colorScheme;
    #colorScheme = inputs.nix-colors.colorSchemes.${cfg.passthru};
    #colorscheme = inputs.nix-colors.colorSchemes.rose-pine-moon;
    # themes: https://github.com/tinted-theming/base16-schemes
    # colorScheme = inputs.nix-colors.colorSchemes.ocean; # black-metal-venom; # TODO add option 
  };
}