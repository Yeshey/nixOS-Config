{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress-force=zstd:6" "noatime" "discard=async" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress-force=zstd:6" "noatime" "discard=async" ];
                  };
                  "@persistent" = {
                    mountpoint = "/persistent";
                    mountOptions = [ "compress-force=zstd:6" "noatime" "discard=async" ];
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = [ "noatime" "discard=async" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
  fileSystems."/persistent".neededForBoot = true;
}
