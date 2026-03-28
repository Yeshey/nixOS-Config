{
  flake.modules.nixos.kakariko = {
    fileSystems."/boot" =
      { device = "/dev/disk/by-uuid/12CE-A600";
        fsType = "vfat";
        options = [ "uid=0" "gid=0" "fmask=0077" "dmask=0077" ]; # https://github.com/NixOS/nixpkgs/issues/279362#issuecomment-1883970541
      };
    fileSystems."/" = # Root filesystem with bcachefs
      { 
        device = "/dev/disk/by-uuid/25da13f9-ca89-4dc7-af80-f168d68f046a";
        fsType = "bcachefs";
        options = [
          "replicas=1"
          # "compression=zstd:1"
          # "foreground_target=nvme"
          # "metadata_target=nvme"
          # "promote_target=nvme"
          # "background_target=sdcard"
        ];
      };
  };
}
