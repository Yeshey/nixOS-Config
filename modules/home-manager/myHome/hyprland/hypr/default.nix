{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.hyprland;
  c = config.myHome.colorScheme.theme.palette;
in
{
  imports = [
    ./hyprlandConf.nix
    inputs.hyprland.homeManagerModules.default
  ];

  options.myHome.hyprland = with lib; {

  };

  config = lib.mkIf cfg.enable {

    myHome.homeApps.kitty.enable = true; # activate the kitty terminal from config

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome.gnome-themes-extra;
      };
    };

    home.packages = [
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      pkgs.gnome.nautilus
      pkgs.wlsunset # for night light
      # clipboard manager
      pkgs.cliphist
      pkgs.copyq
      pkgs.wl-clipboard
    ];

    #test later systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
    wayland.windowManager.hyprland = {
      enable = true;
      #systemd.enable = true;
      systemd = {
        variables = [ "--all" ];
        extraCommands = [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };
    };
  };
}
