{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.ssh;
in
{
  options.myHome.ssh = with lib; {
    enable = mkEnableOption "ssh";
  };

  config = lib.mkIf cfg.enable {

    programs.ssh = {
      enable = true;
      extraConfig = builtins.readFile ./config; # puts in ~/.ssh/config
    };

  };
}
