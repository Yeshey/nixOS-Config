{
  config,
  pkgs,
  lib,
  ...
}:

let
  user = "yeshey";
  repo = "/home/yeshey/PersonalFiles/Servers/minetest/minetestborgbackup";
in
{

  #systemd.tmpfiles.rules = [
  #  "d ${repo} 1777 ${user} ${user} -"
  #];

  # systemctl status borgbackup-job-ServerBackups.service/timer
  services.borgbackup.jobs = {
    ServerBackups = {
      # Use `sudo borg list -v /mnt/hdd-btrfs/Backups/borgbackup` to check the archives created
      # Will spit out all the files inside: `sudo borg list /mnt/hdd-btrfs/Backups/borgbackup::<NameOfArchive>`
      # Use `sudo borg info /mnt/hdd-btrfs/Backups/borgbackup::<NameOfArchive>` to see details
      # Use `sudo borg extract /mnt/hdd-btrfs/Backups/borgbackup::<NameOfArchive>` to extract the specified archive to the current directory
      # Use `sudo borg extract /mnt/hdd-btrfs/Backups/borgbackup::nixOS-laptop-ServerBackups-2023-08-07T00:00:06 /mnt/DataDisk/PersonalFiles/Timeless/Music/AllMusic/` to extract the specified folder in the archive to the current directory
      # Use `sudo borg break-lock /mnt/hdd-btrfs/Backups/borgbackup/` to remove the lock in case you can't access it, make sure nothing is using it
      # Use `sudo systemctl start borgbackup-job-ServerBackups.service` to make a backup right now
      # Watch size of repo: `watch "sudo du -sh /mnt/hdd-btrfs/Backups/borgbackup/ && echo && sudo du -s /mnt/hdd-btrfs/Backups/borgbackup/"`
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
      encryption = {
        mode = "none";
      };
      extraCreateArgs = "--stats"; # --umask 0022 sets premissions so syncthing can runconfig
      #encryption = {
      #  mode = "repokey";
      #  passphrase = "secret";
      #};
      compression = "auto,lzma";
      # user = "yeshey"; # yeshey doesnt have premission to access the minetest folder
      # preHook = "chown -R root ${repo}"; # before a backup set it to root, otherwise it complains there is no repo
      postHook = "chown -R yeshey ${repo}"; # after a backup change premissions to yeshey so syncthing can sync
      paths = [ "/var/lib/minetest/.minetest/games/mineclone2" ]; # paths to backup
      repo = repo;
      prune.keep = {
        within = "1d"; # Keep all archives from the last day
        weekly = 2;
        yearly = 3;
      };
      startAt = "weekly"; # every 3 hours # "*-*-1/3"; # every 3 days # "hourly"; # weekly # daily # *:0/9 every 9 minutes
      persistentTimer = true;
    };
  };
}
