{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.hardware.lvm;
in
{
  options.mySystem.hardware.lvm = with lib; {
    enable = mkEnableOption "lvm";

    cache.enable = mkEnableOption "lvm cache";

    luks.enable = mkEnableOption "lvm luks encryption";
  };

  config = lib.mkIf cfg.enable {

    # Tutorial
    # Check everything `sudo lsblk`
    # Check Logical Volumes(LV): df -h /dev/VG/my_lv
    # Check Physical Volumes(PV): pvs , pvdisplay , and pvscan
    # Check Volume Groups(VG): vgs and vgdisplay
    # Tutorial to create a cache on faster drive with LVM: https://gist.github.com/gabrieljcs/805c183753046dcc6131
    # Use Gparted to increase or decrease PVs

    #boot.initrd.availableKernelModules = [
    #  "usbhid" # not sure if needed
    #];
    environment.systemPackages = with pkgs; [
      lvm2
    ] ++ lib.lists.optionals cfg.luks.enable [
      cryptsetup
    ];

    boot.initrd.kernelModules = [
      # common config
    ] ++ lib.lists.optionals cfg.cache.enable [
      "dm-cache"
      "dm-cache-smq"
      "dm-cache-mq"
      "dm-cache-cleaner"
    ] ++ lib.lists.optionals cfg.luks.enable [
      "aesni_intel"
      "cryptd"
    ];

    boot.kernelModules = [
      # common config
      "kvm-amd"
      "dm_mod"
      "dm-persistent-data"
      "dm-clone"
      "dm-mirror"
      "dm-snapshot"
    ] ++ lib.lists.optionals cfg.cache.enable [
      "dm-cache"
      "dm-cache-smq"
      "dm-bio-prison"
      "dm-writecache"
    ] ++ lib.lists.optionals cfg.luks.enable [
      "dm-crypt"
    ];

    # for LVM: (https://github.com/NixOS/nixpkgs/issues/15516)
    services.lvm.boot.thin.enable = true;

    #boot.initrd.luks.devices.cryptroot.device = lib.mkIf cfg.luks.enable "/dev/disk/by-uuid/UUID-OF-SDA2";
  };

}
