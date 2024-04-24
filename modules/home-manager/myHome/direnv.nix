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
      enable = lib.mkDefault true;
      enableZshIntegration = lib.mkDefault true; # TODO check if zsh enabled?
      nix-direnv.enable = lib.mkDefault true;
    };
  };
}
