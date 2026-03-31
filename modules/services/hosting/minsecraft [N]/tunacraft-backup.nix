{ ... }:
{
  flake.modules.nixos.minecraft =
    { pkgs, ... }:
    {
      # makes a backup of the tunaCraft server to tunaCraftOpenBackups on OneDrive ISCTE,
      # auto-deletes backups older than 10 days
      systemd.services.tunacraft-open-backup = {
        description = "Backup TunaCraft to OneDrive";
        script = ''
          BACKUP_NAME="tunaCraft-$(date +%s)"
          REMOTE="OneDriveISCTE:tunaCraftOpenBackups"
          CURRENT_TIME=$(date +%s)
          CUTOFF_TIME=$((CURRENT_TIME - 864000))  # 10 days in seconds

          ${pkgs.rclone}/bin/rclone copy /srv/minecraft/tunaCraft "$REMOTE/$BACKUP_NAME" \
            --progress \
            --transfers 4 \
            --checkers 8 \
            --config /home/yeshey/.config/rclone/rclone.conf

          echo "Backup completed: $BACKUP_NAME"

          echo "Deleting backups older than $CUTOFF_TIME..."
          ${pkgs.rclone}/bin/rclone lsf "$REMOTE" --dirs-only --config /home/yeshey/.config/rclone/rclone.conf | while read -r folder; do
            folder_timestamp=$(echo "$folder" | grep -oP 'tunaCraft-\K\d+' || echo "")
            if [ -n "$folder_timestamp" ]; then
              if [ "$folder_timestamp" -lt "$CUTOFF_TIME" ]; then
                echo "Deleting old backup: $folder (timestamp: $folder_timestamp)"
                ${pkgs.rclone}/bin/rclone purge "$REMOTE/$folder" --config /home/yeshey/.config/rclone/rclone.conf
              fi
            fi
          done

          echo "Cleanup completed"
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
        path = [ pkgs.rclone pkgs.gnugrep pkgs.coreutils ];
      };

      systemd.timers.tunacraft-open-backup = {
        description = "Timer for TunaCraft OneDrive backup";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-1,4,7,10,13,16,19,22,25,28,31 02:00:00";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    };
}