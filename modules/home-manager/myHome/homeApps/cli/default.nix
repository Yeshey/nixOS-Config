{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.homeApps.cli;
in
{
  imports = [
    ./tmux.nix
    ./general.nix
    ./neovim
    ./git.nix
  ];

  options.myHome.homeApps.cli = {
    enable = lib.mkEnableOption "cli";
  };

  config = lib.mkIf cfg.enable {
    myHome.homeApps.cli.git.enable = lib.mkDefault true;
    myHome.homeApps.cli.general.enable = lib.mkDefault true;
    myHome.homeApps.cli.tmux.enable = lib.mkDefault true;
    myHome.homeApps.cli.neovim.enable = lib.mkDefault true;
  };
  
}
