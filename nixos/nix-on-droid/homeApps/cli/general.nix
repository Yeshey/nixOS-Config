{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.homeApps.cli.general;
in
{
  options.myHome.homeApps.cli.general = {
    enable = (lib.mkEnableOption "general") // {
      default = true;
    };
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && config.myHome.homeApps.cli.enable && cfg.enable) {
    home.packages = with pkgs; [
      # not using bc unfree package is weird and i dont need, use nix on droid directly
    ];
  };
}
