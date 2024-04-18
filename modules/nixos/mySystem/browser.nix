{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.browser;
in
{
  options.mySystem.browser = {
    enable = (lib.mkEnableOption "browser");
    personalGitEnable = (lib.mkEnableOption "personalGitEnable");
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.librewolf;
    };
  };
}
