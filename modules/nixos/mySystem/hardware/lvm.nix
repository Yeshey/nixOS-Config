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
  };

  config = lib.mkIf cfg.enable {

    boot.initrd.availableKernelModules = [
      "usbhid" # not sure if needed
    ];

    boot.initrd.kernelModules = [
      "dm-cache"
      "dm-cache-smq"
      "dm-cache-mq"
      "dm-cache-cleaner"
    ];

    boot.kernelModules = [
      "kvm-amd"
      "dm-cache"
      "dm-cache-smq"
      "dm-persistent-data"
      "dm-bio-prison"
      "dm-clone"
      "dm-crypt"
      "dm-writecache"
      "dm-mirror"
      "dm-snapshot"
    ]; # "coretemp" for temp sensors

    # for LVM: (https://github.com/NixOS/nixpkgs/issues/15516)
    services.lvm.boot.thin.enable = true;

  };
}
