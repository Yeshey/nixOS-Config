{ inputs, ... }:
{
  flake.modules.nixOnDroid.root-droid =
    { pkgs, ... }:
    let
      drop-root = pkgs.writeScriptBin "drop-root" ''
        #!/system/bin/sh

        uid=$(stat -c %u /data/data/com.termux.nix)
        pid=$(pidof -s com.termux.nix)
        if test -z $pid; then
                which -a pidof
                pgrep com.termux.nix
                echo Nix on Droid App process not found
                exit
        fi
        label=$(cat /proc/$pid/attr/current)
        pol_target=$(echo $label | sed 's/.*:\([untrusted_app_[1-9]*\):.*/\1/')
        supolicy --live "allow $pol_target shell_exec file entrypoint"
        groups="3003,3004,2000,9997,20166,50166"
        setpriv="/nix/store/flkd9iwf9mq3lpyz4d519g23nv1b349m-util-linux-2.39.2-bin/bin/setpriv"
        echo setpriving
        $setpriv --reuid $uid --regid $uid --groups $groups --bounding-set -all --selinux-label $label -- /system/bin/sh -c 'exec sh /data/data/com.termux.nix/files/usr/usr/lib/login-inner'
      '';

      root-login = pkgs.writeScriptBin "root-login" ''
        #!/system/bin/sh

        set -eu -o pipefail

        export USER="nix-on-droid"
        export HOME="/data/data/com.termux.nix/files/home"
        export PROOT_TMP_DIR=/data/data/com.termux.nix/files/usr/tmp
        export PROOT_L2S_DIR=/data/data/com.termux.nix/files/usr/.l2s
        export PATH=$PATH:/system/bin/
        export TMPDIR=/data/data/com.termux.nix/files/usr/tmp

        test $(/system/bin/whoami) != root \
          && echo 'use root? [y/N]' && read x && [[ "$x" == "y" ]] \
          && /system/bin/su -c /system/bin/unshare -m $HOME/root_login.sh \
          && exit

        if ! /system/bin/pgrep proot-static > /dev/null; then
          if test -e /data/data/com.termux.nix/files/usr/bin/.proot-static.new; then
            echo "Installing new proot-static..."
            /system/bin/mv /data/data/com.termux.nix/files/usr/bin/.proot-static.new /data/data/com.termux.nix/files/usr/bin/proot-static
          fi

          if test -e /data/data/com.termux.nix/files/usr/usr/lib/.login-inner.new; then
            echo "Installing new login-inner..."
            /system/bin/mv /data/data/com.termux.nix/files/usr/usr/lib/.login-inner.new /data/data/com.termux.nix/files/usr/usr/lib/login-inner
          fi
        fi

        CHROOT_PATH=/data/data/com.termux.nix/files/chroot
        WORKDIR_PATH=/data/data/com.termux.nix/files/overlayfs_workdirs

        mkdir -p $CHROOT_PATH

        NOD_DIRS="nix bin etc tmp usr dev/shm"

        FILES_USR=/data/data/com.termux.nix/files/usr

        busybox mount --make-rslave /

        for DIR in /*/ ; do
                mkdir -p $CHROOT_PATH/$DIR
                for DIR2 in $NOD_DIRS; do
                        if test $DIR == $DIR2 ; then continue 2; fi
                done
                mount --rbind $DIR $CHROOT_PATH/$DIR
        done

        for DIR in $NOD_DIRS; do
                mkdir -p $CHROOT_PATH/$DIR
                mount --rbind $FILES_USR/$DIR $CHROOT_PATH/$DIR
        done

        echo "Keep root? [y/N]"
        read x
        if [[ "$x" == "y" ]]; then
                exec chroot $CHROOT_PATH sh /data/data/com.termux.nix/files/usr/usr/lib/login-inner "$@"
        else
                exec chroot $CHROOT_PATH \
                        sh /data/data/com.termux.nix/files/home/drop_root.sh "$@"
        fi
      '';
    in
    {
      environment.packages = [
        drop-root
        root-login
      ];
    };
}