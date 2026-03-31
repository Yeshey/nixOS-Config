{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.toHost.minecraft;
  extractVersion = name:
    let
      parts = lib.splitString "-" name;          # [ "paper" "1_20_4" "build.40" ]
      verPart = lib.elemAt parts 1;              # "1_20_4"
    in lib.replaceStrings ["_"] ["."] verPart;   # "1.20.4"
in
let 
  # using config from https://github.com/Stefanuk12/nixos-config/blob/main/system/vps/minecraft/servers/fearNightfall/default.nix
  mcVersion = "1.20.1";
  forgeVersion = "47.3.12";
  serverVersion = lib.replaceStrings ["."] ["_"] "forge-${mcVersion}";
  allowUnfreesP = pkg: builtins.elem (lib.getName pkg) [
    "minecraft-server-${mcVersion}"
    "forge-loader"
  ];
  modpack = pkgs.fetchzip {
    url = "https://mediafilez.forgecdn.net/files/6109/390/Fear_Nightfall_Remains_of_Chaos_Server_Pack_v1.0.10.zip";
    hash = "sha256-cBbvPeRT1m0jTERPFI9Jk4nbr2ep9++LvrY7wzIKHXk=";
    extension = "zip";
    stripRoot = false;
  };
  customPkgs = import ./customPkgs { inherit pkgs; };
  overlays = [
    (self: super: {
      forgeServers = customPkgs.forgeServers;
    })
  ];
  pkgs_graalvm = import (pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "a343533bccc62400e8a9560423486a3b6c11a23b";
    hash = "sha256-TofHtnlrOBCxtSZ9nnlsTybDnQXUmQrlIleXF1RQAwQ=";
  }) {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in 
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

  options.toHost.minecraft = {
    enable = (lib.mkEnableOption "minecraft");
  };

    config = lib.mkMerge [
      
    (lib.mkIf cfg.enable {
      nixpkgs.overlays = [ 
        inputs.nix-minecraft.overlay 
      ] ++ overlays;

      services.minecraft-servers = {
        enable = true;
        eula = true;
        openFirewall = true;
        # connect to terminal with sudo tmux -S /run/minecraft/pixelmon.sock attach
        # Use this to get the output continuously if it is crashing to see why:
        # while true; do sudo tmux -S /run/minecraft/zombies.sock capture-pane -p ; sleep 0.2 ; done 
        # And check the hash of all the mods in current folder with:
        # find . -type f -name '*.jar' -exec bash -c 'printf "%s  %s\n" "$(nix-hash --type sha256 --flat --sri "$1")" "$1"' _ {} \;
        # to recreate the world, delete just the world folder
        # might need to delete /run/minecraft/zombies2.sock

        servers.familiaLopesTAISCTE = rec {
          enable = true;
          jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem";
          serverProperties = {
            server-port = 1409;
            "query.port" = 1409;
            server-portv6 = 1410;
            "rcon.port" = 1411;
            difficulty = 2;
            "allow-cheats" = "true";
            gamemode = 0;
            max-players = 60;
            motd = "Família Lopes";
            white-list = false;
            enable-rcon = false;
            "rcon.password" = "hunter2";
            "online-mode"=false;
            "max-tick-time" = -1; # Recommended with lazymc
          };

          # Specify the custom minecraft server package
          #package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version
          package = pkgs.paperServers.paper;

          lazymc = {
            enable = true;
            # see lazymc config here: https://github.com/timvisee/lazymc/blob/master/res/lazymc.toml
            config = {
              public.address = "0.0.0.0:1408"; # aniversario da Mills e do Uno
              public.version = extractVersion package.name;
              motd.sleeping = "☠ LopesCraft is sleeping §2☻ Join to start it up\n§uversion:§c ${extractVersion package.name}";
            };
          };
        }; # End familiaLopesTAISCTE server

        servers.tunaCraft = rec {
          enable = true;
          jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem";
          #managementSystem.systemd-socket.enable = true;
          #managementSystem.tmux.enable = false;
          serverProperties = {
            server-port = 1208;
            "query.port" = 1208;
            server-portv6 = 1209;
            "rcon.port" = 1210;
            difficulty = 2;
            "allow-cheats" = "false";
            gamemode = 0;
            max-players = 100;
            motd = "TunaCraft Running! ♪♫♪";
            white-list = false;
            enable-rcon = false;
            "rcon.password" = "hunter2";
            "online-mode"=false;
            "max-tick-time" = -1; # Recommended with lazymc
          };

          # Specify the custom minecraft server package
          #package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version
          package = pkgs.paperServers.paper;

          lazymc = {
            enable = true;
            # see lazymc config here: https://github.com/timvisee/lazymc/blob/master/res/lazymc.toml
            config = {
              public.address = "0.0.0.0:1207"; # 7 dezembro de 1990 (aniversario taiscte)
              public.version = extractVersion package.name;
              motd.sleeping = "☠ TunaCraft is sleeping §2☻ Join to start it up\n§uversion:§c ${extractVersion package.name}";
              #starting = "§2☻ Server is starting...\n§7⌛ Please wait..."
              #stopping = "☠ Server going to sleep...\n⌛ Please wait..."
            };
          };
        }; # End tunaCraft server

        servers.mainServer = rec {
          enable = true;
          jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem";
          serverProperties = {
            server-port = 44335;
            "query.port"=44335;
            server-portv6 = 44334;
            "rcon.port"=44335;
            "rcon.password" = "hunter2";
            difficulty = 2;
            "allow-cheats" = "true";
            gamemode = 0;
            max-players = 60;
            motd = ":]";
            white-list = false;
            #enable-rcon = false;
            "online-mode"=false;
            "max-tick-time" = -1; # Recommended with lazymc
          };

          # Specify the custom minecraft server package
          #package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version
          package = pkgs.paperServers.paper;

          lazymc = {
            enable = true;
            config = {
              public.address = "0.0.0.0:44329";
              public.version = extractVersion package.name;
              motd.sleeping = "☠ Server is sleeping §2☻ Join to start it up\n§uversion:§c ${extractVersion package.name}";
              # see lazymc config here: https://github.com/timvisee/lazymc/blob/master/res/lazymc.toml
              time.sleep_after = 200; # Sleep after 4 minutes
            };
          };
        }; # End mainInstance server

        servers.craftoria = rec {
          enable = true;
          jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem";
          serverProperties = {
            server-port = 44345;
            "query.port"=44345;
            server-portv6 = 44344;
            "rcon.port"=44345;
            "rcon.password" = "hunter2";
            difficulty = 2;
            "allow-cheats" = "true";
            gamemode = 0;
            max-players = 60;
            motd = ":]";
            white-list = false;
            #enable-rcon = false;
            "online-mode"=false;
            "max-tick-time" = -1; # Recommended with lazymc
          };

          # Specify the custom minecraft server package
          #package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version
          package = pkgs.neoforgeServers.neoforge-1_21_1;

          lazymc = {
            enable = true;
            config = {
              public.address = "0.0.0.0:44339";
              public.version = extractVersion package.name;
              motd.sleeping = "☠ Server is sleeping §2☻ Join to start it up\n§uversion:§c ${extractVersion package.name}";
              # see lazymc config here: https://github.com/timvisee/lazymc/blob/master/res/lazymc.toml
              time.sleep_after = 200; # Sleep after 4 minutes
            };
          };
        }; # End mainInstance server
      };

      # tunaCraft openBackups
      # makes a backup of the tuna craft server to tunaCraftOpenBackups on your iscte onedrive, they can be deleted as you're backing up to restic as well, this is just to share with the tuna folk
      # it auto deletes backups in here older than 10 days
      # Systemd service to backup TunaCraft to OneDrive
      systemd.services.tunacraft-open-backup = {
        description = "Backup TunaCraft to OneDrive";
        
        script = ''
          BACKUP_NAME="tunaCraft-$(date +%s)"
          REMOTE="OneDriveISCTE:tunaCraftOpenBackups"
          CURRENT_TIME=$(date +%s)
          CUTOFF_TIME=$((CURRENT_TIME - 864000))  # 10 days in seconds
          
          # Copy the directory to OneDrive with timestamp
          ${pkgs.rclone}/bin/rclone copy /srv/minecraft/tunaCraft "$REMOTE/$BACKUP_NAME" \
            --progress \
            --transfers 4 \
            --checkers 8 \
            --config /home/yeshey/.config/rclone/rclone.conf
          
          echo "Backup completed: $BACKUP_NAME"
          
          # Delete backups older than 10 days based on folder timestamp
          echo "Deleting backups older than $CUTOFF_TIME..."
          ${pkgs.rclone}/bin/rclone lsf "$REMOTE" --dirs-only --config /home/yeshey/.config/rclone/rclone.conf | while read -r folder; do  # Add --config here too
            # Extract timestamp from folder name (assumes format: tunaCraft-TIMESTAMP)
            folder_timestamp=$(echo "$folder" | grep -oP 'tunaCraft-\K\d+' || echo "")
            
            if [ -n "$folder_timestamp" ]; then
              # Compare timestamps
              if [ "$folder_timestamp" -lt "$CUTOFF_TIME" ]; then
                echo "Deleting old backup: $folder (timestamp: $folder_timestamp)"
                ${pkgs.rclone}/bin/rclone purge "$REMOTE/$folder" --config /home/yeshey/.config/rclone/rclone.conf  # And here
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

      # Timer to run every 3 days
      systemd.timers.tunacraft-open-backup = {
        description = "Timer for TunaCraft OneDrive backup";
        wantedBy = [ "timers.target" ];
        
        timerConfig = {
          OnCalendar = "*-*-1,4,7,10,13,16,19,22,25,28,31 02:00:00";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };

    })
  
    (lib.mkIf (cfg.enable && config.mySystem.impermanence.enable)  {
      environment.persistence."/persistent" = {
        directories = [
          { directory = "/srv/minecraft/mainServer"; user = "minecraft"; group = "minecraft"; mode = "u=rwx,g=rx,o="; }
          { directory = "/srv/minecraft/familiaLopesTAISCTE"; user = "minecraft"; group = "minecraft"; mode = "u=rwx,g=rx,o="; }
          { directory = "/srv/minecraft/tunaCraft"; user = "minecraft"; group = "minecraft"; mode = "u=rwx,g=rx,o="; }
          { directory = "/srv/minecraft/craftoria"; user = "minecraft"; group = "minecraft"; mode = "u=rwx,g=rx,o="; }
        ];
      };
    })
  ];

}

