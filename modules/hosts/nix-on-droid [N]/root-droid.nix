{ ... }:
{
  flake.modules.nixOnDroid.root-droid =
    { config, lib, pkgs, ... }:
    let
      fake-sudo-pkg = pkgs.writeScriptBin "sudo" ''
        #!/system/bin/sh
        exec /system/bin/su -c "$*"
      '';

      # Extended sweep-store: fix both nix store AND .l2s directory ownership
      sweep-store-pkg = pkgs.writeScriptBin "sweep-store" ''
        #!/system/bin/sh
        NOD_UID=$(/system/bin/stat -c %u /data/data/com.termux.nix)
        NOD_GID=$(/system/bin/stat -c %g /data/data/com.termux.nix)
        echo "Sweeping nix store ownership, this will take a while..."
        /system/bin/find /data/data/com.termux.nix/files/usr/nix/store \
          -maxdepth 1 -user root \
          -exec /system/bin/chown -R "$NOD_UID:$NOD_GID" {} \;
        echo "Sweeping nix/var..."
        /system/bin/find /data/data/com.termux.nix/files/usr/nix/var \
          -user root \
          -exec /system/bin/chown "$NOD_UID:$NOD_GID" {} \;
        echo "Sweeping .l2s (proot link2symlink layer)..."
        /system/bin/find /data/data/com.termux.nix/files/usr/.l2s \
          -exec /system/bin/chown "$NOD_UID:$NOD_GID" {} \;
        echo "Done."
      '';

      installationDir = config.build.installationDir;
      fakeProcStat = pkgs.writeText "fakeProcStat" ''
        btime 0
      '';
      fakeProcUptime = pkgs.writeText "fakeProcUptime" ''
        0.00 0.00
      '';

      drop-root = pkgs.writeScript "drop_root.sh" ''
#!/system/bin/sh

uid=$(/system/bin/stat -c %u /data/data/com.termux.nix)
exec ${pkgs.util-linux}/bin/setpriv \
  --reuid $uid --regid $uid \
  --groups 3003,3004,2000,9997,20166,50166 \
  --bounding-set -all \
  -- /system/bin/sh -c 'exec sh /data/data/com.termux.nix/files/usr/usr/lib/login-inner'
      '';

      root-login = pkgs.writeScript "root_login.sh" ''
#!/system/bin/sh

set -eu -o pipefail

export USER="root"
export HOME="/root"
export PROOT_TMP_DIR=/data/data/com.termux.nix/files/usr/tmp
export PROOT_L2S_DIR=/data/data/com.termux.nix/files/usr/.l2s
export PATH=$PATH:/system/bin/
export TMPDIR=/data/data/com.termux.nix/files/usr/tmp

FILES_USR=/data/data/com.termux.nix/files/usr

mkdir -p $FILES_USR/root

# NOTE: No pgrep/swap logic here — that runs in the unprivileged login script
# before su is invoked, avoiding the SELinux cross-context read denial.

CHROOT_PATH=/data/data/com.termux.nix/files/chroot
mkdir -p $CHROOT_PATH
NOD_DIRS="nix bin etc tmp usr dev/shm"
FILES_USR=/data/data/com.termux.nix/files/usr

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
  /system/bin/mount --rbind $FILES_USR/$DIR $CHROOT_PATH/$DIR || true
done

# Bind root home
mkdir -p $CHROOT_PATH/root
/system/bin/mount --rbind $FILES_USR/root $CHROOT_PATH/root

echo "Keep root? [y/N] (chroot user can use a sudo wrapper)"
read x
if [ "$x" = "y" ]; then
  exec /system/bin/chroot $CHROOT_PATH \
    /usr/bin/env HOME=/root USER=root \
    sh /usr/lib/login-inner "$@"
else
  exec /system/bin/chroot $CHROOT_PATH \
    /usr/bin/env HOME=/data/data/com.termux.nix/files/home USER=nix-on-droid \
    sh /data/data/com.termux.nix/files/home/drop_root.sh "$@"
fi
      '';

      login = pkgs.writeScript "login" ''
#!/system/bin/sh
set -eu -o pipefail

export USER="${config.user.userName}"
export HOME="${config.user.home}"
export PROOT_TMP_DIR=${installationDir}/tmp
export PROOT_L2S_DIR=${installationDir}/.l2s
export PATH=$PATH:/system/bin/

# Swap proot-static / login-inner BEFORE su, while still unprivileged.
# This avoids the SELinux cross-context pgrep denial that occurs under su.
if ! /system/bin/pgrep proot-static > /dev/null 2>&1; then
  if test -e ${installationDir}/bin/.proot-static.new; then
    echo "Installing new proot-static..."
    /system/bin/mv ${installationDir}/bin/.proot-static.new ${installationDir}/bin/proot-static
  fi
  if test -e ${installationDir}/usr/lib/.login-inner.new; then
    echo "Installing new login-inner..."
    /system/bin/mv ${installationDir}/usr/lib/.login-inner.new ${installationDir}/usr/lib/login-inner
  fi
fi

if test "$(/system/bin/whoami)" != root; then
  echo 'Use chroot (faster, unsandboxed, requires root)? [y/N]'
  read x
  if [ "$x" = "y" ]; then
    /system/bin/su -c "${config.user.home}/root_login.sh"
    exit
  fi
fi

if [ ! -r /proc/stat ] && [ -e ${installationDir}${fakeProcStat} ]; then
  BIND_PROC_STAT="-b ${installationDir}${fakeProcStat}:/proc/stat"
else
  BIND_PROC_STAT=""
fi

if [ ! -r /proc/uptime ] && [ -e ${installationDir}${fakeProcUptime} ]; then
  BIND_PROC_UPTIME="-b ${installationDir}${fakeProcUptime}:/proc/uptime"
else
  BIND_PROC_UPTIME=""
fi

exec ${installationDir}/bin/proot-static \
  -b ${installationDir}/nix:/nix \
  -b ${installationDir}/bin:/bin \
  -b ${installationDir}/etc:/etc \
  -b ${installationDir}/tmp:/tmp \
  -b ${installationDir}/usr:/usr \
  -b ${installationDir}/dev/shm:/dev/shm \
  $BIND_PROC_STAT \
  $BIND_PROC_UPTIME \
  -b /:/android \
  --sysvipc \
  ${lib.concatStringsSep " " config.build.extraProotOptions} \
  ${installationDir}/bin/sh ${installationDir}/usr/lib/login-inner "$@"
      '';
    in
    {
      environment.files.login = lib.mkForce login;

      environment.motd = lib.mkAfter ''
        Warning: root operations on the nix-store may break permissions.
        If you get permission errors, login as root and run 'sweep-store' to fix it.
      '';

      environment.etc."group".text = lib.mkAfter ''
        nixbld:x:30000:
      '';

      build.activationAfter.install-root-scripts = ''
        cp ${root-login} ${config.user.home}/root_login.sh
        chmod 755 ${config.user.home}/root_login.sh
        cp ${drop-root} ${config.user.home}/drop_root.sh
        chmod 755 ${config.user.home}/drop_root.sh
      '';

      # Run sweep-store automatically on activation to recover from any
      # root-operation ownership drift (covers both nix store and .l2s)
      build.activationAfter.sweep-l2s-ownership = ''
        NOD_UID=$(${pkgs.coreutils}/bin/stat -c %u /data/data/com.termux.nix)
        NOD_GID=$(${pkgs.coreutils}/bin/stat -c %g /data/data/com.termux.nix)
        ${pkgs.findutils}/bin/find ${installationDir}/.l2s \
          -not -user "$NOD_UID" \
          -exec ${pkgs.coreutils}/bin/chown "$NOD_UID:$NOD_GID" {} \; 2>/dev/null || true
      '';

      environment.packages = [ pkgs.bash pkgs.util-linux fake-sudo-pkg sweep-store-pkg ];
    };
}