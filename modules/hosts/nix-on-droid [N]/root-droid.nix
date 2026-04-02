{ inputs, lib, ... }:
{
  flake.modules.nixOnDroid.root-droid =  
    { pkgs, ... }:
    let
      drop-root = pkgs.writeScriptBin "drop-root" ''
        #!${pkgs.runtimeShell}

        uid=$(${pkgs.coreutils}/bin/stat -c %u /data/data/com.termux.nix)
        pid=$(${pkgs.procps}/bin/pidof -s com.termux.nix)
        if test -z "$pid"; then
          ${pkgs.procps}/bin/pgrep com.termux.nix
          echo "Nix on Droid App process not found"
          exit
        fi
        label=$(cat /proc/$pid/attr/current)
        pol_target=$(echo $label | sed 's/.*:\([untrusted_app_[1-9]*\):.*/\1/')
        supolicy --live "allow $pol_target shell_exec file entrypoint"
        groups="3003,3004,2000,9997,20166,50166"
        echo setpriving
        ${pkgs.util-linux}/bin/setpriv \
          --reuid $uid --regid $uid \
          --groups $groups \
          --bounding-set -all \
          --selinux-label $label \
          -- /system/bin/sh -c 'exec sh /data/data/com.termux.nix/files/usr/usr/lib/login-inner'
      '';

      root-shell = pkgs.writeScript "root-shell" ''
        #!/system/bin/sh
        if [ "$(id -u)" != "0" ]; then
          printf "Launch as root? [y/N] "
          read -r ans
          if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
            exec /system/bin/su -c '/data/data/com.termux.nix/files/usr/bin/login'
          fi
        fi
        exec ${pkgs.zsh}/bin/zsh "$@"
      '';
    in
    {
      build.extraProotOptions = [
        "-b /system:/system"
        "-b /vendor:/vendor"
        "-b /data/adb:/data/adb"
      ];

      user.shell = lib.mkForce root-shell;

      environment.packages = [
        drop-root
      ];
    };
}
