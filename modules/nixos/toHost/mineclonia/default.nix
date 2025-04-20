{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.mineclonia;
  port = 30001;
in
{
  imports = [ ./minecloniaNixpkgsModule.nix ]; 

  options.toHost.mineclonia = {
    enable = (lib.mkEnableOption "mineclonia");
    # If left empty, the preStart script will automatically choose the latest tag.
    version = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "0.86.2";
      description = "The VoxeLibre mod version (git tag) to check out. If empty, the latest tag is used.";
    };
  };

  config = lib.mkIf cfg.enable {

    # The problem: https://github.com/NixOS/nixpkgs/issues/383670#issuecomment-2672619706
    # Needed to have multiple minetest instances on the same PC
    nixpkgs.overlays = 
    let
      disablePrometheus = final: prev: {
        minetest = prev.minetest.overrideAttrs (oldAttrs: {
          cmakeFlags = let
            # Filter out any existing flags containing "ENABLE_PROMETHEUS"
            filtered = prev.lib.filter (flag: !(prev.lib.strings.hasInfix "ENABLE_PROMETHEUS" flag)) oldAttrs.cmakeFlags;
          in
            filtered ++ [ "-DENABLE_PROMETHEUS=OFF" ];
        });
      };
    in [ disablePrometheus ];

    environment.systemPackages = with pkgs; [
      gawk
      gnugrep
    ];

    services.mineclonia-server = {
      test2 = {
        enable = true;
        port = port;
        openFirewall = true;
        config = {
          # all default options: https://github.com/minetest/minetest/blob/master/minetest.conf.example
          serverName = "Yeshey mineclonia server";
          serverDescription = "mine here";
          defaultGame = "mineclonia";
          serverAnnounce = false;
          enableDamage = true;
          creativeMode = false;
        };
        world = "MinecloniaFirstServerAnarchy";
        fetchGame = pkgs.fetchurl {
          url    = "https://codeberg.org/mineclonia/mineclonia/archive/0.114.0.tar.gz";
          sha256 = "sha256-VWfv27kRH/ZuDnyW2XKxsVk91991uYuBWYfiSi5nW9g=";
        };
        gameId = "mineclonia";
      };
      test3 = {
        enable = true;
        port = 30002;
        openFirewall = true;
        config = {
          # all default options: https://github.com/minetest/minetest/blob/master/minetest.conf.example
          serverName = "Yeshey mineclonia server 3";
          serverDescription = "mine here";
          defaultGame = "mineclonia";
          serverAnnounce = false;
          enableDamage = true;
          creativeMode = false;
        };
        # world = /var/lib/minetest/.minetest/worlds/MinecloniaFirstServerAnarchy;
        gameId = "mineclonia";
      };
    };

    # In this way, you need to copy the world to the right place while setting the USER and GROUP to minetest, like so:
    # sudo rsync -a /home/yeshey/PersonalFiles/Servers/minetest/MineCloneServerFirst/worlds/world/ /var/lib/minetest/.minetest/worlds/MineCloneFirstServerAnarchy/ && sudo chown -R minetest:minetest /var/lib/minetest/.minetest/worlds/MineCloneFirstServerAnarchy/
    # services.mineclonia-server = {
    #   enable = true;
    #   port = port;
    #   config = {
    #     # all default options: https://github.com/minetest/minetest/blob/master/minetest.conf.example
    #     serverName = "Yeshey mineclonia server";
    #     serverDescription = "mine here";
    #     defaultGame = "mineclonia";
    #     serverAnnounce = false;
    #     enableDamage = true;
    #     creativeMode = false;
    #   }; # TODO put the whole config here instead
    #   world = /var/lib/minetest.minetest/worlds/MinecloniaFirstServerAnarchy;
    #   gameId = "mineclonia";
    # };
    # TODO pull request?
    # Pre-start script to clone/update VoxeLibre.
    # This script will:
    #  1. Ensure the target directory exists.
    #  2. Clone the VoxeLibre repository if the directory is empty.
    #  3. Pull the latest changes if the repo is already cloned.
    #  4. Fetch all tags.
    #  5. If a version is provided in config.toHost.mineclonia.version, reset to that version.
    #     Otherwise, find the latest tag and reset to that.
    # systemd.services.mineclonia-server.preStart =
    #   let
    #     git = pkgs.git;
    #     # Use the new repository URL for VoxeLibre.
    #     mod = "https://codeberg.org/mineclonia/mineclonia.git";
    #     # Set the target directory based on the new gameId.
    #     targetDirectory = "/var/lib/minetest.minetest/games/mineclonia"; # i want to keep my old world
    #   in
    #   lib.mkForce ''
    #     #!/usr/bin/env bash
    #     set -euo pipefail

    #     target_directory="${targetDirectory}"
    #     provided_version="${cfg.version}"

    #     # Ensure the target directory exists.
    #     if [ ! -d "$target_directory" ]; then
    #         mkdir -p "$target_directory" || { echo "Failed to create directory"; exit 1; }
    #     fi

    #     cd "$target_directory" || { echo "Failed to change into directory"; exit 1; }

    #     if [ -z "$(ls -A "$target_directory")" ]; then
    #         ${git}/bin/git clone ${mod} . || { echo "Failed to clone repository"; exit 1; }
    #     else
    #         # Record the current commit
    #         current_commit="$(${git}/bin/git rev-parse HEAD)"
    #         # Pull updates (which might fast-forward the branch)
    #         ${git}/bin/git pull || { echo "Failed to pull latest changes"; exit 1; }
    #         # Reset back to the commit that was current before pulling
    #         ${git}/bin/git reset --hard "$current_commit" || { echo "Failed to reset back to current commit"; exit 1; }
    #     fi


    #     # Fetch all tags.
    #     ${git}/bin/git fetch --tags || { echo "Failed to fetch tags"; exit 1; }

    #     if [ -n "$provided_version" ]; then
    #         version="$provided_version"
    #         echo "Using provided version: $version"
    #     else
    #         # No version provided. Try to get the current tag (if HEAD exactly matches one).
    #         current_tag="$(${git}/bin/git describe --tags 2>/dev/null | cut -d '-' -f1 || true)"
    #         echo "Detected nearest tag (current version): [$current_tag]"
    #         if [ -n "$current_tag" ]; then
    #             echo "Current VoxeLibre/mineclonia mod version is: $current_tag"
    #             # List all tags in version order and find the tag immediately after the current one.
    #             next_tag="$(${git}/bin/git tag --sort=v:refname | ${pkgs.gnugrep}/bin/grep '^[0-9]' | ${pkgs.gawk}/bin/awk -v cur="$current_tag" 'BEGIN {found=0} { if(found){ print; exit } } $0==cur {found=1}')" # to only get version tags, filter for tags that start with a number
    #             if [ -n "$next_tag" ]; then
    #                 version="$next_tag"
    #                 echo "Incrementing to next available version: $version"
    #             else
    #                 version="$current_tag"
    #                 echo "No higher version found. Staying at current version: $version"
    #             fi
    #         else
    #             # No current tag found, so choose the latest tag.
    #             version="$(${git}/bin/git describe --tags "$(${git}/bin/git rev-list --tags --max-count=1)")"
    #             echo "No current version detected. Using latest tag: $version"
    #         fi
    #     fi

    #     ${git}/bin/git reset --hard "$version" || { echo "Failed to reset to tag $version"; exit 1; }

    #     exit 0
    #   '';

    # networking.firewall.allowedUDPPorts = [ port ];
  };
}
