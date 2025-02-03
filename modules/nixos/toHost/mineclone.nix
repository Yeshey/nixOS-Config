{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.mineclone;
  port = 30000;
in
{
  options.toHost.mineclone = {
    enable = (lib.mkEnableOption "mineclone");
    # If left empty, the preStart script will automatically choose the latest tag.
    version = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "0.86.2";
      description = "The VoxeLibre mod version (git tag) to check out. If empty, the latest tag is used.";
    };
  };

  config = lib.mkIf cfg.enable {
    # In this way, you need to copy the world to the right place while setting the USER and GROUP to minetest, like so:
    # sudo rsync -a /home/yeshey/PersonalFiles/Servers/minetest/MineCloneServerFirst/worlds/world/ /var/lib/minetest/.minetest/worlds/MineCloneFirstServerAnarchy/ && sudo chown -R minetest:minetest /var/lib/minetest/.minetest/worlds/MineCloneFirstServerAnarchy/
    services.minetest-server = {
      enable = true;
      port = port;
      config = {
        # all default options: https://github.com/minetest/minetest/blob/master/minetest.conf.example
        serverName = "Yeshey mineclone server";
        serverDescription = "mine here";
        defaultGame = "mineclone2";
        serverAnnounce = false;
        enableDamage = true;
        creativeMode = false;
      }; # TODO put the whole config here instead
      world = /var/lib/minetest/.minetest/worlds/MineCloneFirstServerAnarchy;
      gameId = "voxelibre";
      #gameId = "mineclone2";
    };
    # TODO pull request?
    # Pre-start script to clone/update VoxeLibre.
    # This script will:
    #  1. Ensure the target directory exists.
    #  2. Clone the VoxeLibre repository if the directory is empty.
    #  3. Pull the latest changes if the repo is already cloned.
    #  4. Fetch all tags.
    #  5. If a version is provided in config.toHost.mineclone.version, reset to that version.
    #     Otherwise, find the latest tag and reset to that.
    systemd.services.minetest-server.preStart =
      let
        git = pkgs.git;
        # Use the new repository URL for VoxeLibre.
        mod = "https://git.minetest.land/VoxeLibre/VoxeLibre.git";
        # Set the target directory based on the new gameId.
        targetDirectory = "/var/lib/minetest/.minetest/games/voxelibre";
      in
      lib.mkForce ''
        #!/usr/bin/env bash
        set -euo pipefail

        target_directory="${targetDirectory}"
        provided_version="${cfg.version}"

        # Ensure the target directory exists.
        if [ ! -d "$target_directory" ]; then
            mkdir -p "$target_directory" || { echo "Failed to create directory"; exit 1; }
        fi

        cd "$target_directory" || { echo "Failed to change into directory"; exit 1; }

        # If the directory is empty, clone the repo. Otherwise, update it.
        if [ -z "$(ls -A "$target_directory")" ]; then
            ${git}/bin/git clone ${mod} . || { echo "Failed to clone repository"; exit 1; }
        else
            ${git}/bin/git pull || { echo "Failed to pull latest changes"; exit 1; }
        fi

        # Fetch tags to ensure we have the latest.
        ${git}/bin/git fetch --tags || { echo "Failed to fetch tags"; exit 1; }

        # Determine the version: if provided, use that; otherwise, determine the latest tag.
        if [ -z "$provided_version" ]; then
            version="$(${git}/bin/git describe --tags "$(${git}/bin/git rev-list --tags --max-count=1)")"
            echo "No version provided. Using latest tag: $version"
        else
            version="$provided_version"
            echo "Using provided version: $version"
        fi

        ${git}/bin/git reset --hard "$version" || { echo "Failed to reset to tag $version"; exit 1; }


        exit 0
      '';

    # https://github.com/linuxserver/docker-minetest
    /*
      virtualisation.oci-containers.containers = {
          mineclone-server = {
          image = "lscr.io/linuxserver/minetest:latest";
          volumes = [
              # "${dataStoragePath}/PersonalFiles/Servers/minetest/MineCloneServerFirst:/config/.minetest" # TODO dataStoragePath?
              "/home/yeshey/PersonalFiles/Servers/minetest/MineCloneServerFirst:/config/.minetest" # TODO, if you use ~ it gives an error, need full path
          ];
          environment = {
              PUID = "1000";
              PGID = "1000";
              TZ = "Europe/Lisbon"; # list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
              #CLI_ARGS = "--gameid minetest --port ${port}";
          };
          extraOptions = [ "--platform=linux/arm64" ]; # if it wasn't in a arm system it would be amd64
          ports = [
              "${port}:${port}/udp"
          ];
          #autoStart = true;
          };
      };
    */

    # TODO backups?

    networking.firewall.allowedUDPPorts = [ port ];
  };
}
