{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.cliTools;
in
{
  options.mySystem.cliTools = {
    enable = (lib.mkEnableOption "cliTools");
    personalGitEnable = (lib.mkEnableOption "personalGitEnable");
  };

  config = {
    environment.systemPackages = with pkgs; [
      git
      dnsutils
      pciutils
      curl
      vim # The Nano editor is installed by default.
      htop
      tmux
      wget
      tree
      unzip
    ];
  };
}
