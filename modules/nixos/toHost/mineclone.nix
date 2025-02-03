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
    environment.systemPackages = with pkgs; [
      gawk
      gnugrep
    ];

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

        if [ -z "$(ls -A "$target_directory")" ]; then
            ${git}/bin/git clone ${mod} . || { echo "Failed to clone repository"; exit 1; }
        else
            # Record the current commit
            current_commit="$(${git}/bin/git rev-parse HEAD)"
            # Pull updates (which might fast-forward the branch)
            ${git}/bin/git pull || { echo "Failed to pull latest changes"; exit 1; }
            # Reset back to the commit that was current before pulling
            ${git}/bin/git reset --hard "$current_commit" || { echo "Failed to reset back to current commit"; exit 1; }
        fi


        # Fetch all tags.
        ${git}/bin/git fetch --tags || { echo "Failed to fetch tags"; exit 1; }

        if [ -n "$provided_version" ]; then
            version="$provided_version"
            echo "Using provided version: $version"
        else
            # No version provided. Try to get the current tag (if HEAD exactly matches one).
            current_tag="$(${git}/bin/git describe --tags 2>/dev/null | cut -d '-' -f1 || true)"
            echo "Detected nearest tag (current version): [$current_tag]"
            if [ -n "$current_tag" ]; then
                echo "Current VoxeLibre/Mineclone2 mod version is: $current_tag"
                # List all tags in version order and find the tag immediately after the current one.
                next_tag="$(${git}/bin/git tag --sort=v:refname | ${pkgs.gnugrep}/bin/grep '^[0-9]' | ${pkgs.gawk}/bin/awk -v cur="$current_tag" 'BEGIN {found=0} { if(found){ print; exit } } $0==cur {found=1}')" # to only get version tags, filter for tags that start with a number
                if [ -n "$next_tag" ]; then
                    version="$next_tag"
                    echo "Incrementing to next available version: $version"
                else
                    version="$current_tag"
                    echo "No higher version found. Staying at current version: $version"
                fi
            else
                # No current tag found, so choose the latest tag.
                version="$(${git}/bin/git describe --tags "$(${git}/bin/git rev-list --tags --max-count=1)")"
                echo "No current version detected. Using latest tag: $version"
            fi
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
