{ inputs, ... }:
{
  flake.modules.nixOnDroid.root-droid =
    { config, lib, pkgs, ... }:
    let
      uid = config.user.uid;
      installationDir = config.build.installationDir;

      drop-root = pkgs.writeScript "drop_root.sh" ''
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
        setpriv="${pkgs.util-linux}/bin/setpriv"
        echo setpriving
        $setpriv --reuid $uid --regid $uid --groups $groups --bounding-set -all --selinux-label $label -- /system/bin/sh -c 'exec sh /data/data/com.termux.nix/files/usr/usr/lib/login-inner'
      '';

      root-login = pkgs.writeScript "root_login.sh" ''
        #!/system/bin/sh

        set -eu -o pipefail

        export USER="nix-on-droid"
        export HOME="/data/data/com.termux.nix/files/home"
        export PROOT_TMP_DIR=/data/data/com.termux.nix/files/usr/tmp
        export PROOT_L2S_DIR=/data/data/com.termux.nix/files/usr/.l2s
        export PATH=$PATH:/system/bin/
        export TMPDIR=/data/data/com.termux.nix/files/usr/tmp

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
        mkdir -p $CHROOT_PATH
        NOD_DIRS="nix bin etc tmp usr dev/shm"
        FILES_USR=/data/data/com.termux.nix/files/usr

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
          exec ${pkgs.util-linux}/bin/chroot $CHROOT_PATH sh /data/data/com.termux.nix/files/usr/usr/lib/login-inner "$@"
        else
          exec ${pkgs.util-linux}/bin/chroot $CHROOT_PATH \
            sh ${drop-root} "$@"
        fi
      '';

      # This replaces the nix-on-droid login script, running outside proot
      login = pkgs.writeScript "login" ''
        #!/system/bin/sh
        set -eu -o pipefail

        export USER="nix-on-droid"
        export HOME="/data/data/com.termux.nix/files/home"
        export PROOT_TMP_DIR=/data/data/com.termux.nix/files/usr/tmp
        export PROOT_L2S_DIR=/data/data/com.termux.nix/files/usr/.l2s
        export PATH=$PATH:/system/bin/
        export TMPDIR=/data/data/com.termux.nix/files/usr/tmp

        if test $(/system/bin/whoami) != root; then
          echo 'use root? [y/N]'
          read x
          if [[ "$x" == "y" ]]; then
            /system/bin/su -c "${root-login}"
            exit
          fi
        fi

        # Normal non-root proot login (original login script logic preserved)
        if ! /system/bin/pgrep proot-static > /dev/null; then
          if test -e ${installationDir}/bin/.proot-static.new; then
            echo "Installing new proot-static..."
            /system/bin/mv ${installationDir}/bin/.proot-static.new ${installationDir}/bin/proot-static
          fi
          if test -e ${installationDir}/usr/lib/.login-inner.new; then
            echo "Installing new login-inner..."
            /system/bin/mv ${installationDir}/usr/lib/.login-inner.new ${installationDir}/usr/lib/login-inner
          fi
        fi

        if [ ! -r /proc/stat ] && [ -e ${installationDir}/nix/store ] ; then
          BIND_PROC_STAT="-b /dev/null:/proc/stat"
        else
          BIND_PROC_STAT=""
        fi

        exec ${installationDir}/bin/proot-static \
          -b ${installationDir}/nix:/nix \
          -b ${installationDir}/bin:/bin \
          -b ${installationDir}/etc:/etc \
          -b ${installationDir}/tmp:/tmp \
          -b ${installationDir}/usr:/usr \
          -b ${installationDir}/dev/shm:/dev/shm \
          -b /:/android \
          --link2symlink \
          --sysvipc \
          ${lib.concatStringsSep " " config.build.extraProotOptions} \
          ${installationDir}/bin/sh ${installationDir}/usr/lib/login-inner "$@"
      '';
    in
    {
      environment.files.login = lib.mkForce login;

      # Keep drop_root.sh in home so it's accessible from inside the chroot
      build.activationAfter.install-drop-root = ''
        cp ${drop-root} ${config.user.home}/drop_root.sh
        chmod 755 ${config.user.home}/drop_root.sh
      '';

      environment.packages = [ pkgs.busybox pkgs.util-linux ];
    };
}