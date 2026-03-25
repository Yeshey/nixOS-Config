{
  flake.modules.nixos.hyrulecastle = {
    fileSystems."/" = {
      device = "/dev/nvme0n1p5";
      fsType = "btrfs";
      options = [ "subvol=@" "defaults" "x-gvfs-show" "ssd" "compress-force=zstd:3" ];
    };
    fileSystems."/nix" = {
      device = "/dev/nvme0n1p5";
      fsType = "btrfs";
      options = [ "subvol=@nix" "defaults" "ssd" "compress-force=zstd:3" ];
    };
    fileSystems."/persistent" = {
      device = "/dev/nvme0n1p5";
      fsType = "btrfs";
      neededForBoot = true;
      options = [ "subvol=@persistent" "defaults" "ssd" "compress-force=zstd:3" ];
    };
    fileSystems."/swap" = {
      device = "/dev/nvme0n1p5";
      fsType = "btrfs";
      options = [ "subvol=@swap" "defaults" "ssd" ];
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/BB10-773E";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" "defaults" ];
    };
  };
}
