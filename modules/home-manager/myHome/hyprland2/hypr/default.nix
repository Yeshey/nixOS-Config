{ inputs, config, lib, pkgs, ... }:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.hyprland;
  c = config.myHome.colorScheme.theme.palette;
in
{
  imports = [ 
    # ./hyprland-environment.nix # makes second screen not work
    ./hyprlandConf.nix
    inputs.hyprland.homeManagerModules.default
  ];

  options.myHome.hyprland = with lib; {
    
  };

  config = lib.mkIf cfg.enable {

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

    # Wayland, X, etc. support for session vars
    #systemd.user.sessionVariables = config.home-manager.users.justinas.home.sessionVariables;


    home.packages = [ 
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast 
      pkgs.gnome.nautilus
      # pkgs.waybar
      pkgs.wofi
      pkgs.wlsunset # for night light
      pkgs.networkmanagerapplet # for internet

      # clipboard manager
      pkgs.cliphist 
      pkgs.copyq
      pkgs.wl-clipboard

      pkgs.wdisplays
      pkgs.wlogout
      pkgs.blueman
    ];
    
    #test later systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
    wayland.windowManager.hyprland = {
      enable = true;
      #systemd.enable = true;
      systemd = {
        variables = ["--all"];
        extraCommands = [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };

    };
  /*
        home.file.".config/hypr/colors".text = ''
  $background = rgba(1d192bee)
  $foreground = rgba(c3dde7ee)

  $color0 = rgba(1d192bee)
  $color1 = rgba(465EA7ee)
  $color2 = rgba(5A89B6ee)
  $color3 = rgba(6296CAee)
  $color4 = rgba(73B3D4ee)
  $color5 = rgba(7BC7DDee)
  $color6 = rgba(9CB4E3ee)
  $color7 = rgba(c3dde7ee)
  $color8 = rgba(889aa1ee)
  $color9 = rgba(465EA7ee)
  $color10 = rgba(5A89B6ee)
  $color11 = rgba(6296CAee)
  $color12 = rgba(73B3D4ee)
  $color13 = rgba(7BC7DDee)
  $color14 = rgba(9CB4E3ee)
  $color15 = rgba(c3dde7ee)
      '';
      */
  };
}
