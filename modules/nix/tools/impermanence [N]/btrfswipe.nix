{ inputs, ... }:
{
  flake.modules.nixos.impermanence =
    { lib, pkgs, ... }: # Added 'pkgs' here so we can pull in the required binaries
    {
      # BTRFS root-wipe on boot.
      # When enabled: root subvolume @ is moved to @old_roots/<timestamp> and a
      # fresh @ is created. Old roots older than 2 days are deleted automatically.
      # DO NOT ENABLE until all modules have their impermanence.nix configured.
      boot.initrd.systemd.services.rollback = {
        description = "Rollback BTRFS root subvolume";
        wantedBy = [ "initrd.target" ];
        after = [ "initrd-root-device.target" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        
        # CRITICAL ADDITION: Systemd initrd has a minimal PATH. 
        # This guarantees your script has date, stat, mv, cut (coreutils), 
        # find (findutils), mount (util-linux), and btrfs.
        path = with pkgs; [ coreutils btrfs-progs findutils util-linux ];
        
        script = ''
          mkdir /btrfs_tmp
          mount /dev/sda2 /btrfs_tmp
          if [[ -e /btrfs_tmp/@ ]]; then
              timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@)" "+%Y-%m-%-d_%H:%M:%S")
              mv /btrfs_tmp/@ "/btrfs_tmp/@old_roots/$timestamp"
          fi

          delete_subvolume_recursively() {
              IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                  delete_subvolume_recursively "/btrfs_tmp/$i"
              done
              btrfs subvolume delete "$1"
          }

          for i in $(find /btrfs_tmp/@old_roots/ -maxdepth 1 -mtime +2); do
              delete_subvolume_recursively "$i"
          done

          btrfs subvolume create /btrfs_tmp/@
          umount /btrfs_tmp
        '';
      };
    };
}