{ inputs, ... }:
{
  flake.modules.nixOnDroid.root-droid =
    { config, lib, pkgs, ... }:
    let
      installationDir = config.build.installationDir;

      drop-root = pkgs.writeScript "drop_root.sh" ''
        #!/system/bin/sh

        uid=$(/system/bin/stat -c %u /data/data/com.termux.nix)
        pid=$(/system/bin/pidof -s com.termux.nix)
        if test -z "$pid"; then
          /system/bin/pgrep com.termux.nix || true
          echo "Nix on Droid App process not found"
          exit 1
        fi
        label=$(cat /proc/$pid/attr/current)
        pol_target=$(echo $label | sed 's/.*:\(untrusted_app[^:]*\):.*/\1/')

        # KernelSU: use ksud sepolicy instead of magisk's supolicy
        /data/adb/ksud sepolicy --live "allow $pol_target shell_exec file entrypoint" 2>/dev/null || true

        groups="3003,3004,2000,9997,20166,50166"
        # Inside chroot, nix store is accessible directly at /nix/store
        ${pkgs.util-linux}/bin/setpriv \
          --reuid $uid --regid $uid \
          --groups $groups \
          --bounding-set -all \
          --selinux-label "$label" \
          -- /system/bin/sh -c 'exec sh /data/data/com.termux.nix/files/usr/usr/lib/login-inner'
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

        # make-rslave prevents mount propagation leaking back to host
        # toybox mount may not support it, try and ignore failure
        /system/bin/mount --make-rslave / 2>/dev/null || true

        for DIR in /*/; do
          mkdir -p $CHROOT_PATH/$DIR
          for DIR2 in $NOD_DIRS; do
            if test "$DIR" = "/$DIR2/"; then continue 2; fi
          done
          /system/bin/mount --rbind $DIR $CHROOT_PATH/$DIR 2>/dev/null || true
        done

        for DIR in $NOD_DIRS; do
          mkdir -p $CHROOT_PATH/$DIR
          /system/bin/mount --rbind $FILES_USR/$DIR $CHROOT_PATH/$DIR
        done

        echo "Keep root? [y/N]"
        read x
        if [[ "$x" == "y" ]]; then
          exec /system/bin/chroot $CHROOT_PATH sh /data/data/com.termux.nix/files/usr/usr/lib/login-inner "$@"
        else
          exec /system/bin/chroot $CHROOT_PATH \
            sh /data/data/com.termux.nix/files/home/drop_root.sh "$@"
        fi
      '';

      login = pkgs.writeScript "login" ''
        #!/system/bin/sh
        set -eu -o pipefail

        export USER="nix-on-droid"
        export HOME="/data/data/com.termux.nix/files/home"
        export PROOT_TMP_DIR=/data/data/com.termux.nix/files/usr/tmp
        export PROOT_L2S_DIR=/data/data/com.termux.nix/files/usr/.l2s
        export PATH=$PATH:/system/bin/
        export TMPDIR=/data/data/com.termux.nix/files/usr/tmp

        if test "$(/system/bin/whoami)" != root; then
          echo 'Use chroot (faster, requires root)? [y/N]'
          read x
          if [[ "$x" == "y" ]]; then
            /system/bin/su -c "/data/data/com.termux.nix/files/home/root_login.sh"
            exit
          fi
        fi

        # Normal proot login
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

        if [ ! -r /proc/stat ] && [ -e ${installationDir}/nix/store ]; then
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
      build.activationAfter.replace-login = ''
        echo "Installing custom chroot-aware login..."
        $DRY_RUN_CMD cp ${login} ${installationDir}/bin/login.custom
        $DRY_RUN_CMD chmod 755 ${installationDir}/bin/login.custom
        $DRY_RUN_CMD ln --symbolic --force ${installationDir}/bin/login.custom ${installationDir}/bin/login
      '';

      build.activationAfter.install-root-scripts = ''
        cp ${root-login} ${config.user.home}/root_login.sh
        chmod 755 ${config.user.home}/root_login.sh
        cp ${drop-root} ${config.user.home}/drop_root.sh
        chmod 755 ${config.user.home}/drop_root.sh
      '';

      environment.packages = [ pkgs.util-linux ];
    };
}