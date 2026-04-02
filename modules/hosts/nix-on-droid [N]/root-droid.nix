{ inputs, ... }:
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

      root-login = pkgs.writeScriptBin "root-login" ''
        #!${pkgs.runtimeShell}

        set -eu -o pipefail

        export USER="nix-on-droid"
        export HOME="/data/data/com.termux.nix/files/home"
        export PROOT_TMP_DIR=/data/data/com.termux.nix/files/usr/tmp
        export PROOT_L2S_DIR=/data/data/com.termux.nix/files/usr/.l2s
        export PATH=$PATH:/system/bin/
        export TMPDIR=/data/data/com.termux.nix/files/usr/tmp

        if [ "$(${pkgs.coreutils}/bin/whoami)" != "root" ]; then
          echo 'use root? [y/N]'
          read x
          if [[ "$x" == "y" ]]; then
            /system/bin/su -c "${pkgs.util-linux}/bin/unshare -m $(${pkgs.coreutils}/bin/realpath $0)"
          fi
          exit
        fi

        if ! ${pkgs.procps}/bin/pgrep proot-static > /dev/null 2>&1; then
          if test -e /data/data/com.termux.nix/files/usr/bin/.proot-static.new; then
            echo "Installing new proot-static..."
            mv /data/data/com.termux.nix/files/usr/bin/.proot-static.new \
              /data/data/com.termux.nix/files/usr/bin/proot-static
          fi

          if test -e /data/data/com.termux.nix/files/usr/usr/lib/.login-inner.new; then
            echo "Installing new login-inner..."
            mv /data/data/com.termux.nix/files/usr/usr/lib/.login-inner.new \
              /data/data/com.termux.nix/files/usr/usr/lib/login-inner
          fi
        fi

        CHROOT_PATH=/data/data/com.termux.nix/files/chroot
        FILES_USR=/data/data/com.termux.nix/files/usr
        NOD_DIRS="nix bin etc tmp usr dev/shm"

        mkdir -p $CHROOT_PATH

        ${pkgs.busybox}/bin/busybox mount --make-rslave /

        for DIR in /*/; do
          mkdir -p $CHROOT_PATH/$DIR
          for DIR2 in $NOD_DIRS; do
            if test "$DIR" = "/$DIR2/"; then continue 2; fi
          done
          ${pkgs.util-linux}/bin/mount --rbind $DIR $CHROOT_PATH/$DIR
        done

        for DIR in $NOD_DIRS; do
          mkdir -p $CHROOT_PATH/$DIR
          ${pkgs.util-linux}/bin/mount --rbind $FILES_USR/$DIR $CHROOT_PATH/$DIR
        done

        echo "Keep root? [y/N]"
        read x
        if [[ "$x" == "y" ]]; then
          exec ${pkgs.util-linux}/bin/chroot $CHROOT_PATH \
            sh /data/data/com.termux.nix/files/usr/usr/lib/login-inner "$@"
        else
          exec ${pkgs.util-linux}/bin/chroot $CHROOT_PATH \
            sh /data/data/com.termux.nix/files/home/drop_root.sh "$@"
        fi
      '';
    in
    {
      environment.extraProotOptions = [
        "--bind=/system"
        "--bind=/vendor"   # often needed alongside /system
      ];

      environment.packages = [
        drop-root
        root-login
      ];
    };
}
