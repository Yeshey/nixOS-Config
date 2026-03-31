{ inputs, ... }:
{
  flake.modules.nixos.impermanence =
    { lib, ... }:
    {
      # BTRFS root-wipe on boot.
      # When enabled: root subvolume @ is moved to @old_roots/<timestamp> and a
      # fresh @ is created. Old roots older than 2 days are deleted automatically.
      # DO NOT ENABLE until all modules have their impermanence.nix configured.
      boot.initrd.postResumeCommands = lib.mkAfter ''
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

      environment.persistence."/persistent" = {
        hideMounts = true;
        directories = [
          "/etc/nixos"
          "/var/log"
          "/var/lib/bluetooth"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/lib/systemd/matches"
          "/etc/NetworkManager/system-connections"
          { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
        ];
        files = [
          "/etc/machine-id"
          "/root/.zsh_history"
          "/root/.bash_history"
          { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
        ];
      };

      home-manager.sharedModules = [{
        home.persistence."/persistent" = { };
      }];
    };
}