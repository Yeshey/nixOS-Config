{ config, pkgs, user, location, lib, dataStoragePath, ... }:

{
    imports = [
        # ...
    ];

    #services.minetest-server = {
    #    enable = true;
    #    port = 30000;
    #    configPath = /home/yeshey/PersonalFiles/Servers/minetest/ServerFirst/minetest.conf;
    #    #world = /home/yeshey/PersonalFiles/Servers/minetest/ServerFirst;
    #};

    # https://github.com/linuxserver/docker-minetest
    virtualisation.oci-containers.containers = {
        mineclone-server = {
        image = "lscr.io/linuxserver/minetest:latest";
        volumes = [
            "${dataStoragePath}/PersonalFiles/Servers/minetest/ServerFirst:/config/.minetest"
        ];
        environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "Europe/Lisbon"; # list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
            #CLI_ARGS = "--gameid minetest --port 30000";
        };
        extraOptions = [ "--platform=linux/arm64" ]; # if it wasn't in a arm system it would be amd64
        ports = [
            "30000:30000/udp"
        ];
        #autoStart = true;
        };
    };

    networking.firewall.allowedUDPPorts = [ 30000 ];

}