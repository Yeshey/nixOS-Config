{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.direnv;
in
{
  options.mySystem.direnv = {
    enable = lib.mkEnableOption "direnv";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    programs.direnv = {
      enable = lib.mkOverride 1010 true;
      enableZshIntegration = lib.mkOverride 1010 true;
      enableBashIntegration = lib.mkOverride 1010 true;
      nix-direnv.enable = lib.mkOverride 1010 true;
      settings = {
        global = {
          hide_env_diff = true;
        };
      };
    };

  };
}
