{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.safe-rm;
in
{
  options.myHome.safe-rm = with lib; {
    # enable = mkEnableOption "safe-rm";
  };

  # always active lib.mkIf (config.myHome.enable && cfg.enable)
  config = {

      # changing rm to safe-rm to prevent your dumb ass from deleting your PC
      home.packages = with pkgs; [ 
        coreutils-with-safe-rm
      ];
      programs.bash.enable = true; # makes work in bash
      programs.zsh.enable = true;
      home.shellAliases = {
        sudo="sudo "; # makes aliases work even with sudo behind
        rm = "${pkgs.safe-rm}/bin/safe-rm";
      };

      home.file.".config/safe-rm".text = ''
/
/bin
/boot
/dev
/etc
/home
/lib
/lib64
/lost+found
/nix
/nix/store
/proc
/root
/run
/srv
/sys
/tmp
/usr
/usr/lib
/var
/mnt
/persist
      '';

  };
}