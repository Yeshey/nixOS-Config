{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.stylix;
in
{
  imports = [
    inputs.stylix.homeManagerModules.stylix
  ];

  options.myHome.stylix = with lib; {
    enable = mkEnableOption "stylix";
    wallpaper = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "mandatory for some reason";
    };
    base16Scheme = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "${pkgs.base16-schemes}/share/themes/pop.yaml";
      description = "The theme to use";
    };
    cursor = mkOption {
      type = types.attrs;
      default = { };
      example = {
        package = pkgs.banana-cursor;
        name = "Banana";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    stylix = {
      enable = lib.mkDefault true;
      autoEnable = lib.mkDefault true;
      base16Scheme = lib.mkIf (cfg.base16Scheme != null) cfg.base16Scheme; #"${pkgs.base16-schemes}/share/themes/pop.yaml";
      image = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;
      polarity = lib.mkDefault "dark";

      cursor = cfg.cursor;

      opacity = {
        applications = lib.mkDefault 0.88;
        terminal = lib.mkDefault 0.88;
        desktop = lib.mkDefault 0.88;
        popups = lib.mkDefault 0.88;
      };

      /*
      fonts = {
        sizes = {
          applications = 10;
          terminal = 12;
          desktop = 10;
          popups = 9;
        };

        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };

        monospace = {
          package = pkgs.nerdfonts;
          name = "Fira Code nerd Font Mono";
        };

        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };

        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
      }; */
    };

  };
}