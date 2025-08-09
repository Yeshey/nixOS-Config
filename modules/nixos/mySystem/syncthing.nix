{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.mySystem.syncthing;

  myVersioning = {
    type = "staggered";
    params = {
      cleanInterval = "3600"; # 1 hour in seconds
      maxAge = "864000"; # 11 days in seconds
    };
  };
  devices = {
    "nixOS-Laptop" = {
      id = "MQJK4CT-TFXHX2Y-3E2BSCD-Q7775YX-SX7VHKF-4TY6OA6-OGZO2QX-3NPTWQN";
    };
    "manjaro-Laptop" = {
      id = "HWPEE67-I7DPOPG-H3A3SDX-5HFJK5W-33OIOUO-S6TD5E7-52OAO3B-OFAUAAF";
    };
    "windows-Laptop" = {
      id = "SST7QBM-2SKF4WK-F4RUAA2-ICQ7NBB-LDI3I33-O3DEZZJ-TVXZ3DB-M7IYTAQ";
    };
    "nixOS-Surface" = {
      id = "R54VGF4-E5CDKIZ-ARYKUNC-7L5F25F-TCV5IPL-QVGVHH4-GCHEVHO-NZV4WQ7";
    };
    "nixOS-VM" = {
      id = "GNY2ZH4-Y7W67RF-YXAB7KP-6ZYYAVB-OO2RB4I-UXM2J4X-UNLJGEL-77BHWQY";
    };
    "windows-Surface" = {
      id = "4L2C6IN-PG25JP6-46WCN2B-EKFAHPR-3FE3B2F-JCXRQ5T-MO5PDAA-JWU2IA7";
    };
    "android-A70Phone" = {
      id = "RT3DBUX-VNP5WPX-TZEYYL5-SVKR27H-432WTFY-JD3JOAA-HTL4APW-GRQIBQC";
    };
    "nixOS-arm-oracle" = {
      id = "GRRWAOD-DNXYFHP-TBZIFO7-L2FV6MK-RGLDASJ-ECOU3TA-27DDF4N-QI2WAA7";
    };
  };
  folders = {
    "2026" = {
      path = "${config.mySystem.dataStoragePath}/PersonalFiles/2026";
      devices = lib.mapAttrsToList (name: value: name) devices; # all devices
      # mapAttrsToList: https://ryantm.github.io/nixpkgs/functions/library/attrsets/#function-library-lib.attrsets.mapAttrsToList
      versioning = myVersioning;
      # Ignore patterns: Recorded_Classes 
    };
    "2025" = {
      path = "${config.mySystem.dataStoragePath}/PersonalFiles/2025";
      devices = lib.mapAttrsToList (name: value: name) devices; # all devices
      # mapAttrsToList: https://ryantm.github.io/nixpkgs/functions/library/attrsets/#function-library-lib.attrsets.mapAttrsToList
      versioning = myVersioning;
      # Ignore patterns: Recorded_Classes 
    };
    "A70Camera" = {
      path = "${config.mySystem.dataStoragePath}/PersonalFiles/Timeless/Syncthing/PhoneCamera";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
    "Allsync" = {
      path = "${config.mySystem.dataStoragePath}/PersonalFiles/Timeless/Syncthing/Allsync";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
    "Music" = {
      path = "${config.mySystem.dataStoragePath}/PersonalFiles/Timeless/Music";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
    "Servers" = {
      path = "${config.mySystem.dataStoragePath}/PersonalFiles/Servers";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
    # Config and game files sync
    "ssh" = {
      path = "/home/${config.mySystem.user}/.ssh";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
    "bash&zshHistory" = {
      path = "/home/${config.mySystem.user}";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
    "MinecraftPrismLauncherMainInstance" = {
      path = "/home/${config.mySystem.user}/.local/share/PrismLauncher/instances/MainInstance";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
    "Osu-Lazer" = {
      path = "/home/${config.mySystem.user}/.local/share/osu";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
    "Minetest" = {
      path = "/home/${config.mySystem.user}/.minetest";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
    "PowderToy" = {
      path = "/home/${config.mySystem.user}/.local/share/The Powder Toy";
      devices = lib.mapAttrsToList (name: value: name) devices;
      versioning = myVersioning;
    };
  };
in
{
  options.mySystem.syncthing = {
    enable = lib.mkEnableOption "syncthing";
    dataStoragePath = lib.mkOption {
      type = lib.types.str; # lib.types.path;
      example = "/mnt/DataDisk";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    # Open ports in the firewall.
    # Ports for syncthing: https://docs.syncthing.net/users/firewall.html
    networking.firewall.allowedTCPPorts = [ 22000 ]; # for [ syncthing ]
    networking.firewall.allowedUDPPorts = [
      22000
      21027
    ]; # for [ syncthing syncthing ]
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # Syncthing
    services = {
      syncthing = {
        enable = true;
        user = "${config.mySystem.user}";
        dataDir = "/home/${config.mySystem.user}/Documents"; # Default folder for new synced folders
        configDir = "/home/${config.mySystem.user}/.config/syncthing"; # Folder for Syncthing's settings and keys

        settings = {
          options = {
            relaysEnabled = true;
          };
          devices = devices;
          folders = folders;
        };
      };
    };

    # Only configure persistence if impermanence is enabled
    environment.persistence."/persistent".users.yeshey = lib.mkIf config.mySystem.impermanence.enable {
        directories = [
          ".local/share/PrismLauncher/instances/MainInstance"
          ".local/share/osu"
          ".minetest"
          ".local/share/The Powder Toy"
        ];
      };

    # Ignore Patterns, userActivationScripts isntead of activationScripts to have user premissions
    system.userActivationScripts =
      let
        ignorePattern = folderName: patterns: ''
          mkdir -p ${folders.${folderName}.path}
          echo "${patterns}" > ${folders.${folderName}.path}/.stignore
        '';
      in
      {
        syncthingIgnorePatterns.text = ''
          # 2026
          ${ignorePattern "2026" "
            //*
            //(?i)PhotosAndVideos
            //.git
            *.ipynb
          "}

          # 2025
          ${ignorePattern "2025" "
            //*
            (?i)PhotosAndVideos
            //.git
            Masters
            *.ipynb
          "}

          # A70Camera
          ${ignorePattern "A70Camera" "
            //*
            //(?i)Photos&Videos
          "}

          # Allsync
          ${ignorePattern "Allsync" "
            //*
            //(?i)watch
          "}

          # Music
          ${ignorePattern "Music" "
            //*
            (?i)AllMusic
            (?i)AllMusic-mp3
          "}

          # bash&zshHistory
          ${ignorePattern "bash&zshHistory" "
            !/.zsh_history
            !/.bash_history
            !/.python_history
            // Ignore everything else:
            *
          "}

          # MinecraftPrismLauncherMainInstance
          ${ignorePattern "MinecraftPrismLauncherMainInstance" "
            !/.minecraft/saves
            !/.minecraft/mods
            !/.minecraft/shaderpacks
            !/.minecraft/resourcepacks

            !/minecraft/saves
            !/minecraft/mods
            !/minecraft/shaderpacks
            !/minecraft/resourcepacks

            // Don't ignore top level files for prism launcher to find the instance
            !/*.json
            !/*.cfg
            
            // Ignore everything else:
            *
          "}

          # Minetest
          ${ignorePattern "Minetest" "
            !/games
            !/worlds
            
            // Ignore everything else:
            *
          "}

          # Osu-Lazer 
          ${ignorePattern "Osu-Lazer" "
            # 1) Un-ignore the maps directory and all its contents
            !/files
            !/files/**

            # 2) Un-ignore screenshots (and all screenshot files)
            !/screenshots
            !/screenshots/**

            # 3) Un-ignore your collection database and client realm
            !/collection.db
            !/client.realm

            # 4) Ignore everything else
            *
          "}
        '';
      };

    # A systemd timer to delete all the sync-conflict files
    # systemd.timers."delete-sync-conflicts" = {
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     Persistent = true; # If missed, run on boot (https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
    #     OnCalendar = "*-*-1,4,7,10,13,16,19,22,25,28"; # Every three days approximatley
    #     Unit = "delete-sync-conflicts.service";
    #   };
    # };
    # systemd.services."delete-sync-conflicts" = {
    #   script = ''
    #     # Ignore What's inside Trash etc...
    #       if [ -d "/mnt" ]; then
    #           ${pkgs.findutils}/bin/find /mnt -mount -mindepth 1 -type f -not \( -path '*/.Trash-1000/*' -or -path '*.local/share/Trash/*' \) -name '*.sync-conflict-*' -ls -delete
    #       fi

    #       if [ -d "/home" ]; then
    #           ${pkgs.findutils}/bin/find /home -mount -mindepth 1 -type f -not \( -path '*/.Trash-1000/*' -or -path '*.local/share/Trash/*' \) -name '*.sync-conflict-*' -ls -delete
    #       fi
    #   '';
    #   serviceConfig = {
    #     Type = "oneshot";
    #     User = "${config.mySystem.user}";
    #   };
    # };

    # makeDesktopItem https://discourse.nixos.org/t/proper-icon-when-using-makedesktopitem/32026
    # Syncthing desktop shortcut
    environment.systemPackages =
      with pkgs;
      let
        syncthingWeb = makeDesktopItem {
          name = "Syncthing";
          desktopName = "Syncthing";
          genericName = "Syncthing Web App";
          exec = ''xdg-open "http://127.0.0.1:8384#"'';
          icon = "firefox";
          categories = [
            "GTK"
            "X-WebApps"
          ];
          mimeTypes = [
            "text/html"
            "text/xml"
            "application/xhtml_xml"
          ];
        };
      in
      [
        xdg-utils
        syncthingWeb
      ];
  };
}
