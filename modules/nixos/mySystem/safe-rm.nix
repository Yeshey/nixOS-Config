{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.safe-rm;
in
{
  options.mySystem.safe-rm = with lib; {
    # enable = mkEnableOption "safe-rm";
  };

  # always active lib.mkIf (config.mySystem.enable && cfg.enable) 
  config = { 

    # changing rm to safe-rm to prevent your dumb ass from deleting your PC
    environment.shellAliases = {
      sudo="sudo "; # makes aliases work even with sudo behind
      rm = "${pkgs.safe-rm}/bin/safe-rm";
    };
    environment.systemPackages = with pkgs; [ 
      coreutils-with-safe-rm # straight up changes the binary
    ];

    system.activationScripts = {
      safe-rm.text = ''
        echo "
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
        " > "/etc/safe-rm.conf"
      '';
    };

  };
}
