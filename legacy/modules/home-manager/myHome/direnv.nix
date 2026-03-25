{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.direnv;
in
{
  options.myHome.direnv = with lib; {
    enable = mkEnableOption "direnv";
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable) {

    programs.direnv = {
      enable = lib.mkOverride 1010 true;
      enableZshIntegration = lib.mkOverride 1010 true;
      enableBashIntegration = lib.mkOverride 1010 true;
      nix-direnv.enable = lib.mkOverride 1010 true;
      config = {
        global = {
          hide_env_diff = true;
        };
      };
    };

  };
}
