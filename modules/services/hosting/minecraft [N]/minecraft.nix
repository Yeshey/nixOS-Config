{ inputs, ... }:
{
  flake.modules.nixos.minecraft =
    { pkgs, lib, ... }:
    let
      extractVersion = name:
        let
          parts = lib.splitString "-" name;
          verPart = lib.elemAt parts 1;
        in lib.replaceStrings [ "_" ] [ "." ] verPart;
    in
    {
      imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

      nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

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
            "online-mode" = false;
            "max-tick-time" = -1;
          };
          package = pkgs.paperServers.paper;
          lazymc = {
            enable = true;
            config = {
              public.address = "0.0.0.0:1408";
              public.version = extractVersion package.name;
              motd.sleeping = "☠ LopesCraft is sleeping §2☻ Join to start it up\n§uversion:§c ${extractVersion package.name}";
            };
          };
        };

        servers.tunaCraft = rec {
          enable = true;
          jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem";
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
            "online-mode" = false;
            "max-tick-time" = -1;
          };
          package = pkgs.paperServers.paper;
          lazymc = {
            enable = true;
            config = {
              public.address = "0.0.0.0:1207";
              public.version = extractVersion package.name;
              motd.sleeping = "☠ TunaCraft is sleeping §2☻ Join to start it up\n§uversion:§c ${extractVersion package.name}";
            };
          };
        };

        servers.mainServer = rec {
          enable = true;
          jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem";
          serverProperties = {
            server-port = 44335;
            "query.port" = 44335;
            server-portv6 = 44334;
            "rcon.port" = 44335;
            "rcon.password" = "hunter2";
            difficulty = 2;
            "allow-cheats" = "true";
            gamemode = 0;
            max-players = 60;
            motd = ":]";
            white-list = false;
            "online-mode" = false;
            "max-tick-time" = -1;
          };
          package = pkgs.paperServers.paper;
          lazymc = {
            enable = true;
            config = {
              public.address = "0.0.0.0:44329";
              public.version = extractVersion package.name;
              motd.sleeping = "☠ Server is sleeping §2☻ Join to start it up\n§uversion:§c ${extractVersion package.name}";
              time.sleep_after = 200;
            };
          };
        };

        servers.craftoria = rec {
          enable = true;
          jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem";
          serverProperties = {
            server-port = 44345;
            "query.port" = 44345;
            server-portv6 = 44344;
            "rcon.port" = 44345;
            "rcon.password" = "hunter2";
            difficulty = 2;
            "allow-cheats" = "true";
            gamemode = 0;
            max-players = 60;
            motd = ":]";
            white-list = false;
            "online-mode" = false;
            "max-tick-time" = -1;
          };
          package = pkgs.neoforgeServers.neoforge-1_21_1;
          lazymc = {
            enable = true;
            config = {
              public.address = "0.0.0.0:44339";
              public.version = extractVersion package.name;
              motd.sleeping = "☠ Server is sleeping §2☻ Join to start it up\n§uversion:§c ${extractVersion package.name}";
              time.sleep_after = 200;
            };
          };
        };
      };
    };
}