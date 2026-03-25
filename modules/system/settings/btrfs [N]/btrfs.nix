{ ... }:
{

  flake.modules.nixos.btrfs = {
    virtualisation.docker.storageDriver = "btrfs";

    # hide your internal BTRFS subvolume partitions from file managers like Nautilus
    services.udev.extraRules = ''
      KERNEL=="nvme0n1p5", ENV{UDISKS_IGNORE}="1"
      KERNEL=="sda1", ENV{UDISKS_IGNORE}="1"
      ENV{ID_FS_UUID}=="2dff5eb1-1dce-46fd-a0cc-510e5dd3b666", ENV{UDISKS_IGNORE}="1"
    '';
  };
}
