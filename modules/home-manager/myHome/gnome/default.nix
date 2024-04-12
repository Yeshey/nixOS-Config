{ config, lib, pkgs, ... }:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.gnome;
in
{
  imports = [ 
    ./dconf.nix 
    #./alacritty.nix # TODO make a option for the terminal emulator, shouldn-t be inside gnome, and should still get the template colours
    #./kitty.nix
  ];
  options.myHome.gnome = with lib; {
    enable = mkEnableOption "gnome";
    /*
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
      }; 
    }; */ 
    font = {
      package = mkOption {
        type = types.package;
        default = pkgs.nerdfonts.override { fonts = [ "Hack" ]; };
      };
      name = mkOption {
        type = types.str;
        default = "Hack Nerd Font";
      };
      size = mkOption {
        type = types.int;
        default = 14;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # For gnome
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.burn-my-windows
      gnomeExtensions.hibernate-status-button
      gnomeExtensions.tray-icons-reloaded
    ];
    dconf.settings = {
      "org/gnome/desktop/background" = {
        picture-uri = "file://${wallpaper}";
        picture-uri-dark = "file://${wallpaper}";
      };
    };
  };
}
