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

  config = lib.mkIf cfg.enable {

    programs.direnv = {
      enable = lib.mkOverride 1010 true;
      enableZshIntegration = lib.mkOverride 1010 true; # TODO check if zsh enabled?
      nix-direnv.enable = lib.mkOverride 1010 true;
    };
  };
}
