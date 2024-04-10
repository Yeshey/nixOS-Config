{ config, pkgs, user, location, lib, ... }:

let
    port = 30000;
in
{
    imports = [
        # ...
    ];

    # In this way, you need to copy the world to the right place while setting the USER and GROUP to minetest, like so:
    # sudo rsync -a /home/yeshey/PersonalFiles/Servers/minetest/MineCloneServerFirst/worlds/world/ /var/lib/minetest/.minetest/worlds/MineCloneFirstServerAnarchy/ && sudo chown -R minetest:minetest /var/lib/minetest/.minetest/worlds/MineCloneFirstServerAnarchy/
    services.minetest-server = {
        enable = true;
        port = port;
        config = { # all default options: https://github.com/minetest/minetest/blob/master/minetest.conf.example
            serverName = "Yeshey mineclone server";
            serverDescription = "mine here";
            defaultGame = "mineclone2";
            serverAnnounce = false;
            enableDamage = true;
            creativeMode = false;
        }; #TODO put the whole config here instead
        world = /var/lib/minetest/.minetest/worlds/MineCloneFirstServerAnarchy;
        gameId = "mineclone2";
    };
    # TODO pull request?
      systemd.services.minetest-server.preStart = let 
        cfg = config.services.minetest-server;
        # Define variables
        git = pkgs.git;
        version = "0.86.2";
        targetDirectory = "/var/lib/minetest/.minetest/games/mineclone2";
      in lib.mkForce ''
        # Define the target directory
        target_directory="${targetDirectory}"

        # Check if the target directory exists
        if [ ! -d "$target_directory" ]; then
            # Directory doesn't exist, create it
            mkdir -p "$target_directory" || { echo "Failed to create directory"; exit 1; }
        fi

        # Move into the target directory
        cd "$target_directory" || { echo "Failed to move into directory"; exit 1; }

        # Check if the directory is empty
        if [ -z "$(ls -A "$target_directory")" ]; then
            # Directory is empty, perform git clone
            ${git}/bin/git clone https://git.minetest.land/MineClone2/MineClone2.git . || { echo "Failed to clone repository"; exit 1; }
        else
            # Directory is not empty, perform git pull to get the latest changes
            ${git}/bin/git pull || { echo "Failed to pull latest changes"; exit 1; }
        fi

        # Reset the HEAD to the specified version
        ${git}/bin/git reset --hard ${version} || { echo "Failed to reset to tag ${version}"; exit 1; }

        # If we've reached this point, everything succeeded
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

    networking.firewall.allowedUDPPorts = [ port ]; # TODO, make port a variable

}