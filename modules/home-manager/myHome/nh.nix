{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.nh;
in
{
  options.myHome.nh = with lib; {
    enable = mkEnableOption "nh";
  };

  config = lib.mkIf (config.myHome.enable && cfg.enable)  {

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 2d --keep 3";
      flake = "/home/yeshey/.setup";
    };

    # changing rm to safe-rm to prevent your dumb ass from deleting your PC
    home.packages = with pkgs; [ 
      nix-output-monitor
    ];
    programs.bash.enable = true; # makes work in bash
    programs.zsh.enable = true;
    home.shellAliases = {
      sudo="sudo "; # makes aliases work even with sudo behind
      nix = "${pkgs.nix-output-monitor}/bin/nom";
    };

  };
}
