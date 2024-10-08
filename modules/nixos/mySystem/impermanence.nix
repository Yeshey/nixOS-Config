{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.mySystem.impermanence;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.mySystem.impermanence = with lib; {
    enable = mkEnableOption "impermanence";
  };

  config = lib.mkMerge [
    # Requires btrfs with fileSystems."/nix" and fileSystems."/persist" (with neededForBoot = true) and root subvolumes. 
    # Using systemd for boot as well.
    # Should have fileSystems."/swap" in a seperate subvolume as well.
    {
      # For /etc/machie-id file already exists https://discourse.nixos.org/t/impermanence-a-file-already-exists-at-etc-machine-id/20267
      #environment.etc.machine-id.source = builtins.toFile "machine-id" "08adbbff76d1468db8c83f09834d622b";
      # I think I can ignore


      programs.fuse.userAllowOther = true; # needed for nonchelant home manager impermanance stuff when impermanance is not used
      /*

      # https://discourse.nixos.org/t/using-immutable-users-with-impermanence-on-luks/43459
      # cleans older than 30 days
      boot.initrd.systemd.services.clean-old-roots = {
        requires = ["dev-mapper-cryptroot.device"];
        after = ["dev-mapper-cryptroot.device"];
        before = [
          "sysroot.mount"
        ];
        wantedBy = ["initrd.target"];
        script = ''
          mkdir /btrfs_tmp
          mount /dev/disk/by-label/nixos /btrfs_tmp

          delete_subvolume_recursively() {
              IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                  delete_subvolume_recursively "/btrfs_tmp/$i"
              done
              btrfs subvolume delete "$1"
          }

          for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
              delete_subvolume_recursively "$i"
              echo "deleted subvolume $i"
          done

          umount /btrfs_tmp
        '';
      };
      */

    }
    ( lib.mkIf (config.mySystem.enable && cfg.enable) {

      # https://discourse.nixos.org/t/using-immutable-users-with-impermanence-on-luks/43459
      # mv root subvolume to old_roots
      boot.initrd.systemd.services.wipe-my-fs = {
        requires = ["dev-mapper-cryptroot.device"];
        after = ["dev-mapper-cryptroot.device" "clean-old-roots.service"];
        before = [
          "sysroot.mount"
        ];
        wantedBy = ["initrd.target"];
        script = ''
          mkdir /btrfs_tmp
          mount /dev/disk/by-label/nixos /btrfs_tmp
          if [[ -e /btrfs_tmp/root ]]; then
              mkdir -p /btrfs_tmp/old_roots
              timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
              mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
          fi

          btrfs subvolume create /btrfs_tmp/root
          umount /btrfs_tmp
        '';
      };

      # needed for home manager to have premissions to access the folder (comment in video https://youtu.be/YPKwkWtK7l0?si=FxmuAGEF0wN96_Gv)
      systemd.tmpfiles.rules = [
        "d /persist/home/ 1777 root root -"     # /persist/home created, owned by root
        "d /persist/home/yeshey 0770 yeshey users -" # /persist/home/<user> created, owned by that user
      ];
      environment.persistence."/persist" = {
        enable = true;  # NB: Defaults to true, not needed
        hideMounts = true;
        directories = [
          "/etc/nixos"
          "/var/log"
          "/var/lib/bluetooth"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/etc/NetworkManager/system-connections"
          "/etc/ssh" # keepfor agenix ye
          { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
        ];
        files = [
          "/etc/machine-id"
          { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
        ];
      };
    })
  ];
}
