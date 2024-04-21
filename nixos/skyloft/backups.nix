{ config, pkgs, lib, ... }:

let
  
in
{

    # systemctl status borgbackup-job-mySystemBackup.service/timer
    services.borgbackup.jobs = {
      ServerBackups = {
        # Use `sudo borg list -v /mnt/hdd-btrfs/Backups/borgbackup` to check the archives created
        # Use `sudo borg info /mnt/hdd-btrfs/Backups/borgbackup::<NameOfArchive>` to see details
        # Use `sudo borg extract /mnt/hdd-btrfs/Backups/borgbackup::<NameOfArchive>` to extract the specified archive to the current directory
        # Use `sudo borg extract /mnt/hdd-btrfs/Backups/borgbackup::nixOS-laptop-mySystemBackup-2023-08-07T00:00:06 /mnt/DataDisk/PersonalFiles/Timeless/Music/AllMusic/` to extract the specified folder in the archive to the current directory
        # Use `sudo borg break-lock /mnt/hdd-btrfs/Backups/borgbackup/` to remove the lock in case you can't access it, make sure nothing is using it
        # Use `sudo systemctl start borgbackup-job-mySystemBackup.service` to make a backup right now
        # Watch size of repo: `watch "sudo du -sh /mnt/hdd-btrfs/Backups/borgbackup/ && echo && sudo du -s /mnt/hdd-btrfs/Backups/borgbackup/"`
        # TODO dataStoragePath = "/mnt/DataDisk"; and user = "yeshey";
        # see if the ~ works
        paths = [ "/var/lib/minetest/.minetest/games/mineclone2" ]; 
        exclude = [ 
            # Largest cache dirs
            ".cache"
            "*/cache2" # firefox
            "*/Cache"
            ".config/Slack/logs"
            ".config/Code/CachedData"
            ".container-diff"
            ".npm/_cacache"
            # Work related dirs
            "*/node_modules"
            "*/bower_components"
            "*/_build"
            "*/.tox"
            "*/venv"
            "*/.venv"
            # Personal Home Dirs
            "*cache*"
            "*/Android"
            "*/.gradle"
            "*/.var"
            "*/.cabal"
            "*/.vscode"
            "*/.stremio-server"
            "*/grapejuice"
            "*/baloo"
            "*/share/containers"
            "*/lutris"
            "*/Steam"
            "*/.config"
            "*/Trash"
            "*/Games"
        ];
        repo = /home/yeshey/PersonalFiles/Servers/minetest/minetestborgbackup;
        encryption = {
          mode = "none";
        };
        prune.keep = {
          within = "1d"; # Keep all archives from the last day
          daily = 2; # keep the latest backup on each day, up to 7 most recent days with backups (days without backups do not count)
          weekly = 2; 
          monthly = 3;
          yearly = 3;
        };
        extraCreateArgs = "--stats";
        #encryption = {
        #  mode = "repokey";
        #  passphrase = "secret";
        #};
        compression = "auto,lzma";
        startAt = "weekly"; # every 3 hours # "*-*-1/3"; # every 3 days # "hourly"; # weekly # daily # *:0/9 every 9 minutes
      };
    };

}

