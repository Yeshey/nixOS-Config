{ inputs, config, lib, pkgs, ... }:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.plasma;
in
{
  imports = [ 
    inputs.plasma-manager.homeManagerModules.plasma-manager
    # ./plasmaconf.nix 
  ];
  options.myHome.plasma = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {

  programs.plasma = {
    enable = true;

    workspace = {
      clickItemTo = "select";
      lookAndFeel = "org.kde.breezedark.desktop";
      cursorTheme = "Bibata-Modern-Ice";
      iconTheme = "Papirus-Dark";
      wallpaper = wallpaper;
    };
  };

  };
}
