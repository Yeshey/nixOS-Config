{
  flake.modules.nixos.safe-rm =
    { pkgs, ... }:
    {
      environment.shellAliases = {
        sudo = "sudo ";
        rm   = "${pkgs.safe-rm}/bin/safe-rm";
      };

      environment.systemPackages = [ pkgs.local.coreutils-with-safe-rm ];

      system.activationScripts.safe-rm.text = ''
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
/persistent
        " > "/etc/safe-rm.conf"
      '';
    };

  flake.modules.homeManager.safe-rm =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.local.coreutils-with-safe-rm ];

      programs.bash.enable = true;
      programs.zsh.enable  = true;

      home.shellAliases = {
        sudo = "sudo ";
        rm   = "${pkgs.safe-rm}/bin/safe-rm";
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
/persistent
      '';
    };
}