{ inputs, config, lib, pkgs, ... }:

let
  wallpaper = config.myHome.wallpaper;
  cfg = config.myHome.hyprland;
  c = config.myHome.colorScheme.theme.palette;
in
{
  imports = [ 

    inputs.hyprland.homeManagerModules.default
    ./binds.nix
    ./rules.nix
    ./settings.nix

      # ./hyprbars.nix # TODO, why doesnt this work..

  ];
  options.myHome.hyprland = with lib; {
    enable = mkEnableOption "hyprland";
  };

  config = lib.mkIf cfg.enable {
    # https://github.com/fufexan/dotfiles
    home.packages = [
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast # screenshot helper
      pkgs.wofi
    ];

    # enable hyprland
    wayland.windowManager.hyprland = {
      enable = true;

      # plugins = [inputs.hyprland-plugins.packages.${pkgs.system}.csgo-vulkan-fix];

      systemd = {
        variables = ["--all"];
        extraCommands = [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };
    };
  };
}
