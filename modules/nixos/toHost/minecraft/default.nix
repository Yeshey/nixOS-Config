{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.toHost.minecraft;
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
    inherit (pkgs) system;
  };
in 
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

  options.toHost.minecraft = {
    enable = (lib.mkEnableOption "minecraft");
  };

  config = lib.mkIf cfg.enable {

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


      # this server is at /srv/minecraft/pixelmon
      servers.mainServer = {
        enable = true;
        # options specific for pixelmon?
        jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem";
        serverProperties = {
          server-port = 44329;
          server-portv6 = 44330;
          difficulty = 2;
          "allow-cheats" = "true";
          gamemode = 0;
          max-players = 60;
          motd = "MINE!!";
          white-list = false;
          enable-rcon = false;
          "rcon.password" = "hunter2";
          "rcon.port"=44331;
          "query.port"=44329;
          "online-mode"=false;
          "max-tick-time" = -1; # Recommended with lazymc
        };

        # Specify the custom minecraft server package
        #package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version
        package = pkgs.paperServers.paper;

        lazymc = {
          enable = true;
          config = {
            # see lazymc config here: https://github.com/timvisee/lazymc/blob/master/res/lazymc.toml
            forge = true;
            time.sleep_after = 240; # Sleep after 4 minutes
          };
        };
      }; # End mainInstance server

      # this server is at /srv/minecraft/pixelmon
      servers.pixelmon = {
        enable = true;
        # options specific for pixelmon?
        jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem";
        serverProperties = {
          server-port = 44332;
          server-portv6 = 44333;
          difficulty = 2;
          "allow-cheats" = "true";
          gamemode = 0;
          max-players = 60;
          motd = "MINE!!";
          white-list = false;
          enable-rcon = true;
          "rcon.password" = "hunter2";
          "rcon.port"=44334;
          "query.port"=44332;
          "online-mode"=false;
          "max-tick-time" = -1; # Recommended with lazymc
        };

        # Specify the custom minecraft server package
        #package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version
        package = pkgs.forgeServers.${serverVersion}.override { # forge for minecraft 1.20.1
          loaderVersion = forgeVersion;
          jre_headless = pkgs_graalvm.graalvm-ce;
        };

        lazymc = {
          enable = true;
          package = let
          # you can use https://lazamar.co.uk/nix-versions/
            pkgs-with-lazymc_0_2_10 = import (builtins.fetchTarball {
                url = "https://github.com/NixOS/nixpkgs/archive/336eda0d07dc5e2be1f923990ad9fdb6bc8e28e3.tar.gz";
                sha256 = "sha256:0v8vnmgw7cifsp5irib1wkc0bpxzqcarlv8mdybk6dck5m7p10lr";
            }) { inherit (pkgs) system; };
          in pkgs-with-lazymc_0_2_10.lazymc;
          config = {
            # see lazymc config here: https://github.com/timvisee/lazymc/blob/master/res/lazymc.toml
            forge = true;
            time.sleep_after = 240; # Sleep after 4 minutes
          };
        };

        symlinks = {
          mods = pkgs.linkFarmFromDrvs "mods" (
            # PIXELMON mods and friends
            builtins.attrValues {
              luckyBlock = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4817/267/lucky-block-forge-1.20.1-13.0.jar";
                # replace with the real hash:
                sha256 = "sha256-wQHdMm5e1CHQNz7sBlBUz1lyE09jnzhT01VC53ouGEw=";
              };
              Pixelmon = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4744/5/Pixelmon-1.20.1-9.2.2-universal.jar";
                sha256 = "sha256-ZL76UjLdWGqSjOJoqOXpxmf8RtvmrNvorrsNTYkXmoQ=";
              };
              ProjectE = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4901/949/ProjectE-1.20.1-PE1.0.1.jar";
                sha256 = "sha256-9R84flYwfnzaJpFcoMeJdg2F6XqLQLi/oJiL5mNx0Bg=";
              };
              journeymap = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5789/363/journeymap-1.20.1-5.10.3-forge.jar";
                sha256 = "sha256-iyZ5t7SIHgqkMP0kNF6kRt6Rn6+KRb0qcdN8fo/2rh4=";
              };
              jei = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6075/247/jei-1.20.1-forge-15.20.0.106.jar";
                sha256 = "sha256-49jyxAKPpDE2jUK94luSsiEL3dLh+1mpMtDCzGLdNYc=";
              };
              configuredForge = pkgs.fetchurl { # needed for jei (just enough items)
                url = "https://mediafilez.forgecdn.net/files/5180/900/configured-forge-1.20.1-2.2.3.jar";
                sha256 = "sha256-Bdzt3VeCX5ERNckpUE7zILdZU9BefckY26WKBXTlMV8=";
              };
              betterfurnaces = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5128/669/BetterFurnaces-1.20.1-1.1.3-forge.jar";
                sha256 = "sha256-sKAty2rO8b6JTFXhTrRSbgQMwWG5VrTVClTLcD6fNEk=";
              };
              architectury = pkgs.fetchurl { # needed for betterfurnaces
                url = "https://mediafilez.forgecdn.net/files/5137/938/architectury-9.2.14-forge.jar";
                sha256 = "sha256-IYtHHQuKH2zaFM/BvrnusN9UMEUArMbFYT2biOxl2a8=";
              };
              factory-api = pkgs.fetchurl { # needed for betterfurnaces
                url = "https://mediafilez.forgecdn.net/files/5168/342/FactoryAPI-1.20.1-2.1.4-forge.jar";
                sha256 = "sha256-lFUuTqQW8mFKox5gP432e65Xi1SBHbD+Scj7x5twzuI=";
              };

              # Some Server-side and Client-side Performance mods (from https://github.com/TheUsefulLists/UsefulMods/blob/main/Performance/Performance120.md)
              ferritecore = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4810/975/ferritecore-6.0.1-forge.jar";
                sha256 = "sha256-nCyTlqSeeW2ISXdYyqRjfSvLtDPDGOLdnOvP+68PbFQ=";
              };
              memoryleakfix = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/NRjRiSSD/versions/3w0IxNtk/memoryleakfix-forge-1.17%2B-1.1.5.jar";
                sha256 = "sha256-klw9tOHQhaQ8TSvqpO7Bg2fCKryQws6FlLihKf0/KN0=";
              };
              modernfix = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/nmDcB62a/versions/5m06ltZw/modernfix-forge-5.21.0%2Bmc1.20.1.jar";
                sha256 = "sha256-NlhoeI0/xFPyfget/Do/ogSnkb/Rwx7xpsczVTXWAIk=";
              };
              krypton = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/jiDwS0W1/krypton-0.2.3.jar";
                sha256 = "sha256-aa0YECBs4SGBsbCDZA8ETn4lB4HDbJbGVerDYgkFdpg=";
              };
              cupboard = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5470/32/cupboard-1.20.1-2.7.jar";
                sha256 = "sha256-Y6G26OnP/VPyg/rgT2S41j3Kqpn+Djg7tmTyPsh9OV8=";
              };

              # Some only Server-side Performance mods (from https://github.com/TheUsefulLists/UsefulMods/blob/main/Performance/Performance120.md)
              clumps = pkgs.fetchurl {
                url = "https://media.forgecdn.net/files/4598/426/Clumps-forge-1.20.1-12.0.0.2.jar";
                sha256 = "sha256-hiEtI3xLZFd8YMfLmXyXH17tk40/YgisZQE9nB+Stz4=";
              };
              dynview = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5345/889/dynview-1.20.1-4.0.jar";
                sha256 = "sha256-qM+zu6/CgrZkn8sP9YL4gVd8BYTf9quwVpkUSI/F7nw=";
              };
              fastasyncworldsave = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6303/144/fastasyncworldsave-1.20.1-2.4.jar";
                sha256 = "sha256-617dYM/Di1OVdVwhDWPs+MAXdYD9Diytl96QrKxAJFc=";
              };
              smoothchunk = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6296/598/smoothchunk-1.20.1-4.1.jar";
                sha256 = "sha256-DuSPe/eAcKfLWFhJL6pv59WEQ6y9l6klR71mTucQ5cE=";
              };
            }
          );
        };
      }; # End pixelmon server

      servers.zombies2 = {
        enable = true;
        # options specific for pixelmon?
        jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled";
        # connect to terminal with sudo tmux -S /run/minecraft/zombies.sock attach
        serverProperties = {
          level-seed="-8932854458220952308"; # cool seed
          server-port = 44340;
          server-portv6 = 44341;
          difficulty = 2;
          "allow-cheats" = "true";
          gamemode = 0;
          max-players = 60;
          motd = "MINE!!";
          white-list = false;
          enable-rcon = true;
          "rcon.password" = "hunter2";
          "rcon.port"=44342;
          "query.port"=44340;
          "online-mode"=false;
          "max-tick-time" = -1; # Recommended with lazymc
        };

        # Specify the custom minecraft server package
        #package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version
        package = pkgs.forgeServers.${serverVersion}.override { # forge for minecraft 1.20.1
          loaderVersion = forgeVersion;
          jre_headless = pkgs_graalvm.graalvm-ce;
        };

        lazymc = {
          enable = true;
          package = let
          # you can use https://lazamar.co.uk/nix-versions/
            pkgs-with-lazymc_0_2_10 = import (builtins.fetchTarball {
                url = "https://github.com/NixOS/nixpkgs/archive/336eda0d07dc5e2be1f923990ad9fdb6bc8e28e3.tar.gz";
                sha256 = "sha256:0v8vnmgw7cifsp5irib1wkc0bpxzqcarlv8mdybk6dck5m7p10lr";
            }) { inherit (pkgs) system; };
          in pkgs-with-lazymc_0_2_10.lazymc;
          config = {
            # see lazymc config here: https://github.com/timvisee/lazymc/blob/master/res/lazymc.toml
            forge = true;
            time.sleep_after = 240; # Sleep after 4 minutes
          };
        };

        symlinks = {
          mods = pkgs.linkFarmFromDrvs "mods" (
            builtins.attrValues {
              MajruszsProgressiveDifficulty = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5293/465/majruszs-difficulty-forge-1.20.1-1.9.10.jar";
                sha256 = "sha256-Okfe54nkkFDigZ4cFzx/xNgCCoYE5+2a+0AXqUG6hvM=";
              };
              MajruszsLibrary = pkgs.fetchurl { # requiered by MajruszsProgressiveDifficulty
                url = "https://mediafilez.forgecdn.net/files/5302/100/majrusz-library-forge-1.20.1-7.0.8.jar";
                sha256 = "sha256-TVj8LbJjQ9axY9u4+MmOVUrab/+2NLmJbC0nRikJBUg=";
              };
              ImprovedMobs = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5950/926/improvedmobs-1.20.1-1.13.2-forge.jar";
                sha256 = "sha256-JmuKeFkL6s0goLwsmGywcVraIVVOBY98xseH9/yLvy0=";
              };
              tenshilib = pkgs.fetchurl { # requiered by improvedmobs
                url = "https://mediafilez.forgecdn.net/files/5240/455/tenshilib-1.20.1-1.7.6-forge.jar";
                sha256 = "sha256-otvZ14OC0W72fUEAscs5DUO0s8heqXcOU876fd+ZR9g=";
              };
              MobSunscreen = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4647/106/mobsunscreen-forge-1.20.1-3.1.1.jar";
                sha256 = "sha256-klldrNOl/M77YYGUUxZQZvl4U3gVot3UtNdMfQxpnJE=";
              };
              BiomesOPlenty = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6364/65/BiomesOPlenty-forge-1.20.1-19.0.0.96.jar";
                sha256 = "sha256-Mw9IJIesMTVVe26JjX4a5TMDIenP1bpj4ToWzy6Ni5g=";
              };
              LostCities = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6174/986/lostcities-1.20-7.3.6.jar";
                sha256 = "sha256-Az3KcvS7LXa3rij8C/FFNci88r8QZqzBH5GvB2EfYe4=";
              };
              glitchCore = pkgs.fetchurl { # requiered by BiomesOPlenty
                url = "https://mediafilez.forgecdn.net/files/5787/839/GlitchCore-forge-1.20.1-0.0.1.1.jar";
                sha256 = "sha256-5CqLUT2gipEMEzyur62fwvzCL9qqLrPiUW6REqWg22E=";
              };
              terraBlender = pkgs.fetchurl { # requiered by BiomesOPlenty
                url = "https://mediafilez.forgecdn.net/files/6290/448/TerraBlender-forge-1.20.1-3.0.1.10.jar";
                sha256 = "sha256-wQkBb0bKm9rmmXa/CAu/Lo5ZaMtmwKeIRfjKavXbvrE=";
              };
              journeymap = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5789/363/journeymap-1.20.1-5.10.3-forge.jar";
                sha256 = "sha256-iyZ5t7SIHgqkMP0kNF6kRt6Rn6+KRb0qcdN8fo/2rh4=";
              };
              jei = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6075/247/jei-1.20.1-forge-15.20.0.106.jar";
                sha256 = "sha256-49jyxAKPpDE2jUK94luSsiEL3dLh+1mpMtDCzGLdNYc=";
              };
              configuredForge = pkgs.fetchurl { # needed for jei (just enough items)
                url = "https://mediafilez.forgecdn.net/files/5180/900/configured-forge-1.20.1-2.2.3.jar";
                sha256 = "sha256-Bdzt3VeCX5ERNckpUE7zILdZU9BefckY26WKBXTlMV8=";
              };
              GatewaysToEternity = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5703/251/GatewaysToEternity-1.20.1-4.2.6.jar";
                sha256 = "sha256-9hAdnxGxrtb5dHO3l7RyAdA9ip3LIpT0vLnV9c2/QT8=";
              };
              Placebo = pkgs.fetchurl { # requiered by GatewaysToEternity
                url = "https://mediafilez.forgecdn.net/files/6274/231/Placebo-1.20.1-8.6.3.jar";
                sha256 = "sha256-HN+QbPvLteW+LvG7ch95oksBvSrFWcjNv7dpP2JCFXE=";
              };
              attributeslibApothicAttributes = pkgs.fetchurl { # requiered by GatewaysToEternity
                url = "https://mediafilez.forgecdn.net/files/5634/71/ApothicAttributes-1.20.1-1.3.7.jar";
                sha256 = "sha256-aEh7EcDU4vZ6hfKwS/ZemawVKU8pI/Q5H4PpVCKTGHo=";
              };
              ars_nouveau = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5894/609/ars_nouveau-1.20.1-4.12.6-all.jar";
                sha256 = "sha256-IypDPd5Jd7IdEYVXAly7P6+5fNy4Eu5ifmUtDYupSiQ=";
              };
              curios = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6418/456/curios-forge-5.14.1%2B1.20.1.jar";
                sha256 = "sha256-HoF5GaNbN88wUkquxz8MpRMEUvI/Fo+ESFTfKC645R8=";
              };
              graveStone = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5794/82/gravestone-forge-1.20.1-1.0.24.jar";
                sha256 = "sha256-9N/JKpvkFHFVgXIp26sNRtX0zmErOCaTtlh0r9qD11g=";
              };              
              ProjectE = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4901/949/ProjectE-1.20.1-PE1.0.1.jar";
                sha256 = "sha256-9R84flYwfnzaJpFcoMeJdg2F6XqLQLi/oJiL5mNx0Bg=";
              };

              # Some Server-side and Client-side Performance mods (from https://github.com/TheUsefulLists/UsefulMods/blob/main/Performance/Performance120.md)
              ferritecore = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4810/975/ferritecore-6.0.1-forge.jar";
                sha256 = "sha256-nCyTlqSeeW2ISXdYyqRjfSvLtDPDGOLdnOvP+68PbFQ=";
              };
              memoryleakfix = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/NRjRiSSD/versions/3w0IxNtk/memoryleakfix-forge-1.17%2B-1.1.5.jar";
                sha256 = "sha256-klw9tOHQhaQ8TSvqpO7Bg2fCKryQws6FlLihKf0/KN0=";
              };
              modernfix = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/nmDcB62a/versions/5m06ltZw/modernfix-forge-5.21.0%2Bmc1.20.1.jar";
                sha256 = "sha256-NlhoeI0/xFPyfget/Do/ogSnkb/Rwx7xpsczVTXWAIk=";
              };
              krypton = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/jiDwS0W1/krypton-0.2.3.jar";
                sha256 = "sha256-aa0YECBs4SGBsbCDZA8ETn4lB4HDbJbGVerDYgkFdpg=";
              };
              cupboard = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5470/32/cupboard-1.20.1-2.7.jar";
                sha256 = "sha256-Y6G26OnP/VPyg/rgT2S41j3Kqpn+Djg7tmTyPsh9OV8=";
              };
              aquaculture2 = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6296/111/Aquaculture-1.20.1-2.5.5.jar"; 
                sha256 = "sha256-gYnQmt3lWM0u+XYn6UgOS2IMP6HeftBk0cIDRiiIQeU=";
              };

              # Some only Server-side Performance mods (from https://github.com/TheUsefulLists/UsefulMods/blob/main/Performance/Performance120.md)
              clumps = pkgs.fetchurl {
                url = "https://media.forgecdn.net/files/4598/426/Clumps-forge-1.20.1-12.0.0.2.jar";
                sha256 = "sha256-hiEtI3xLZFd8YMfLmXyXH17tk40/YgisZQE9nB+Stz4=";
              };
              dynview = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5345/889/dynview-1.20.1-4.0.jar";
                sha256 = "sha256-qM+zu6/CgrZkn8sP9YL4gVd8BYTf9quwVpkUSI/F7nw=";
              };
              fastasyncworldsave = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6303/144/fastasyncworldsave-1.20.1-2.4.jar";
                sha256 = "sha256-617dYM/Di1OVdVwhDWPs+MAXdYD9Diytl96QrKxAJFc=";
              };
              smoothchunk = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6296/598/smoothchunk-1.20.1-4.1.jar";
                sha256 = "sha256-DuSPe/eAcKfLWFhJL6pv59WEQ6y9l6klR71mTucQ5cE=";
              };
            }
          );
        };
        # inside config folder, mobsunscreen-common.toml file (NEEDS TO BE rw!!)
        files = {
          # make zombies not burn on sunlight
          "config/mobsunscreen-common.toml" = pkgs.writeTextFile {
            name = "mobsunscreen-common.toml";
            text = builtins.readFile ./mobsunscreen-common.toml;
          };
          # adds abandoned cities, some config details: has 0.25 ruins, 0.1 vines, 0.005 cities rarity
          "world/serverconfig/lostcities-server.toml" = pkgs.writeTextFile {
            name = "lostcities-server.toml";
            text = builtins.readFile ./lostcities-server.toml;
          };
          # disables all things for skeletons and creepers (make creepers not break blocks)
          # make difficultity increase 2 times slower
          # use /improvedmobs difficulty set -10
          "config/improvedmobs/common.toml" = pkgs.writeTextFile {
            name = "common.toml";
            text = builtins.readFile ./improvedmobs-common.toml;
          };
        };
      }; # End zombies2 server


      servers.botw = {
        enable = true;
        # general options
        jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled";
        # connect to terminal with sudo tmux -S /run/minecraft/botw.sock attach
        serverProperties = {
          # level-seed="-8932854458220952308"; # cool seed
          server-port = 44345;
          server-portv6 = 44346;
          difficulty = 2;
          "allow-cheats" = "true";
          gamemode = 0;
          max-players = 100;
          motd = "Breath Of the Wild :)";
          white-list = false;
          enable-rcon = false;
          "rcon.password" = "hunter2";
          "rcon.port"=44347;
          "query.port"=44345;
          "online-mode"=false;
          "max-tick-time" = -1; # Recommended with lazymc
        };

        # Specify the custom minecraft server package
        #package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version
        package = pkgs.fabricServers.fabric-1_21_4.override { loaderVersion = "0.16.14"; };

        lazymc = {
          enable = true;
          # package = let
          # # you can use https://lazamar.co.uk/nix-versions/
          #   pkgs-with-lazymc_0_2_10 = import (builtins.fetchTarball {
          #       url = "https://github.com/NixOS/nixpkgs/archive/336eda0d07dc5e2be1f923990ad9fdb6bc8e28e3.tar.gz";
          #       sha256 = "sha256:0v8vnmgw7cifsp5irib1wkc0bpxzqcarlv8mdybk6dck5m7p10lr";
          #   }) { inherit (pkgs) system; };
          # in pkgs-with-lazymc_0_2_10.lazymc;
          config = {
            # see lazymc config here: https://github.com/timvisee/lazymc/blob/master/res/lazymc.toml
            forge = false;
          };
        };

        symlinks = {
          mods = pkgs.linkFarmFromDrvs "mods" (
            builtins.attrValues {
              TravelersBackpack = pkgs.fetchurl {
                 url = "https://mediafilez.forgecdn.net/files/6556/44/travelersbackpack-fabric-1.21.4-10.4.13.jar";
                sha256 = "sha256-Wzej9iSNp0p7nzbiES/TjvnHpKaRWL1wnoN1KsYH8Kk=";
              };
              cardinal-components-api = pkgs.fetchurl { # needed by travelersbackpack
                url = "https://mediafilez.forgecdn.net/files/6027/922/cardinal-components-api-6.2.2.jar";
                sha256 = "sha256-LhlW1ZSCd2cWbCeq3ckl7TOqoltJr7KXZdnsMSLhhl0=";
              };
              cloth-config = pkgs.fetchurl { # needed by travelersbackpack
                url = "https://mediafilez.forgecdn.net/files/5987/42/cloth-config-17.0.144-fabric.jar";
                sha256 = "sha256-H9oMSonU8HXlGz61VwpJEocGVtJS2AbqMJHSu8Bngeo=";
              };
              RoughlyEnoughItems = pkgs.fetchurl { # requiered by MajruszsProgressiveDifficulty
                url = "https://mediafilez.forgecdn.net/files/6406/333/RoughlyEnoughItems-18.0.804-fabric.jar";
                sha256 = "sha256-HGb2P6waxjxSjh3djTq3/DG0/x4VkeyY9BNEVtHft5Y=";
              };
              architectury = pkgs.fetchurl { # needed by roughly enough items
                url = "https://mediafilez.forgecdn.net/files/6206/630/architectury-15.0.3-fabric.jar";
                sha256 = "sha256-nhH4HueGQBom3khql5hodVmlMp/sPNQV6U+jw5WDUvM=";
              };
              journeymap = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6550/381/journeymap-fabric-1.21.4-6.0.0-beta.47.jar";
                sha256 = "sha256-wi7EL6AHjvu1nYFlm7GJxRuXa45C/Q5ilCcavq0pqM0=";
              };
              sharedinv = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/MhGYDguV/versions/XFlgkgyM/sharedinv-1.2.1.jar";
                sha256 = "sha256-VlHP//rrylAWxGNNzcDZ58qRohzybu1POhjbU+TDleI=";
              };
              itemalchemy = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6546/161/itemalchemy-1.1.2.jar";
                sha256 = "sha256-pM3EtGwhYq30AYSfe/x/pAjffFlT2GT1JkFB8u7mLCY=";
              };
              mcpitanlib = pkgs.fetchurl { # needed by itemalchemy
                url = "https://mediafilez.forgecdn.net/files/6560/796/mcpitanlib-3.2.7-1.21.4-fabric.jar";
                sha256 = "sha256-USfB4dI0yZ7CjhDGAfLd5WMjQj56Y/TJyyj8gIwqTpQ=";
              };
              eg_particle_interactions = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/xFCYuAs8/versions/oZCuVdkW/eg_particle_interactions-0.6.2-fabric-mc1.21.4.jar";
                sha256 = "sha256-F38it/PtsWHmmtNSj9QHm/OR6shvPmH1VhF87cJHExQ=";
              };
              TreeTimberFabric = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6027/13/TreeTimberFabric-1.0.0.jar";
                sha256 = "sha256-MHaDascALHIttkWaRNHUDnt4yGHWO4kijxcebEgTimo=";
              };
              setworldspawnpoint = pkgs.fetchurl { # preserve Y axis in world spawn
                url = "https://mediafilez.forgecdn.net/files/6185/213/setworldspawnpoint-1.21.4-3.5.jar";
                sha256 = "sha256-J7Xr8o6HxIAGrK9girW5QeoS68feNvKa1gZYRmqc2DI=";
              };
              collective = pkgs.fetchurl { # needed by setworldspawnpoint
                url = "https://mediafilez.forgecdn.net/files/6429/225/collective-1.21.4-8.3.jar";
                sha256 = "sha256-mIeBy9zRcRUZlskk3BDSA518tyLQ04FwCRpDsboMhGo=";
              };

              # Performance & quality of life
              sodium = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/AANobbMI/versions/c3YkZvne/sodium-fabric-0.6.13%2Bmc1.21.4.jar";
                sha256 = "sha256-kreWI/wA8PlIAFoK5BbLQqUWRvJCO0A24n6GfkABpH4=";
              };
              lithium = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6401/281/lithium-fabric-0.15.3%2Bmc1.21.4.jar";
                sha256 = "sha256-FTiR6NaYj+3/pQmIUacloTfD5coEqJqN9An+sxNiPrQ=";
              };
              DistantHorizons = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/uCdwusMi/versions/94McsAoL/DistantHorizons-neoforge-fabric-2.3.2-b-1.21.4.jar";
                sha256 = "sha256-uf/8HNmeY9oRLHyqRkVYGi1YapF+WxZyhXiMnqxSCzI=";
              };
              # good shaders to use with distantHorizons: Bliss-Shader, 
              particle-rain = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/nrikgvxm/versions/NUvMa5Xt/particle-rain-3.3.3.jar";
                sha256 = "sha256-4nFBT4oK9oDXEoXLF5Ku+n8y8pGh/k2BnQfyhdEGaV8=";
              };
              ambientsounds = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6206/435/AmbientSounds_FABRIC_v6.1.7_mc1.21.4.jar";
                sha256 = "sha256-bWeXhxliyexsTkqes/179Fl+QUwSGAvjVHNoVG648JQ=";
              };
              creativecore = pkgs.fetchurl { # needed for ambient sounds
                url = "https://mediafilez.forgecdn.net/files/6192/466/CreativeCore_FABRIC_v2.12.35_mc1.21.4.jar";
                sha256 = "sha256-o7sOd9p+dS77JA8WQai/Jjlr8cYEtzO+mT/cGX3hrKw=";
              };
              PresenceFootsteps = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/rcTfTZr3/versions/Oxj0KnG2/PresenceFootsteps-1.11.0%2B1.21.4.jar";
                sha256 = "sha256-STihPBcr6gjKInJQ1KRpqDD44C++bOfvXr8advWqgpU=";
              };
              # with the below two installed mods you can now run fresh-animations resource pack: https://www.curseforge.com/minecraft/texture-packs/fresh-animations
              # other good resourcepacks: gentler weather and VanillaMashup
              entity_model_features = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6001/154/entity_model_features_fabric_1.21.4-2.4.1.jar";
                sha256 = "sha256-DJEj2cvrUIW7FnQi3udFwvmUIAEWPMP+gLSw9VmBpCo=";
              };
              entity_texture_features = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6045/344/entity_texture_features_fabric_1.21.4-6.2.10.jar";
                sha256 = "sha256-MIdRkuj9zcLlrdEM+z6Kl+cJYJXneDhou5HJiVmBFLE=";
              };            
              modernfix = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/nmDcB62a/versions/ZGxQddYr/modernfix-fabric-5.20.3%2Bmc1.21.4.jar";
                sha256 = "sha256-zrQ15ShzUtw1Xty1yxxO/n8xYofpaATSF9ewEeqE/d4=";
              };
              iris = pkgs.fetchurl { # for shaders
                url = "https://cdn.modrinth.com/data/YL57xq9U/versions/Ca054sTe/iris-fabric-1.8.8%2Bmc1.21.4.jar";
                sha256 = "sha256-cFcbI9TeF644BRX7TJ2t2C2W9+wbVzVThYoHu4BEXak=";
              };
              Zoomify = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/w7ThoJFB/versions/RKRjd2h1/Zoomify-2.14.2%2B1.21.3.jar";
                sha256 = "sha256-9nZ/X2tCV2/UwYRDnkAjBBBhb+NRn+OJb51qcPigtbI=";
              };
              yet_another_config_lib = pkgs.fetchurl { # needed by zoomify
                url = "https://cdn.modrinth.com/data/1eAoo2KR/versions/XeXZrziK/yet_another_config_lib_v3-3.6.6%2B1.21.4-fabric.jar";
                sha256 = "sha256-dA1DpD99+uSn3r4v2WqTpsSfa2jrpOie8d6HBs5AT60=";
              };
              fabric-language-kotlin = pkgs.fetchurl { # needed by zoomify
                url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/iqWDz8qt/fabric-language-kotlin-1.13.3%2Bkotlin.2.1.21.jar";
                sha256 = "sha256-0d58143zqMbIazgji/1pFA0b8OrV2O9bukjPPKE0LYs=";
              };
              ImmediatelyFast = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/5ZwdcRci/versions/ddjmgf0b/ImmediatelyFast-Fabric-1.8.0%2B1.21.4.jar";
                sha256 = "sha256-EwniJ08fd2sV1yGWzZdlMeQV4EkEQOn4j5BkxDK/lP0=";
              };
              ferritecore = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/uXXizFIs/versions/IPM0JlHd/ferritecore-7.1.1-fabric.jar";
                sha256 = "sha256-DdXpIDVSAk445zoPW0aoLrZvAxiyMonGhCsmhmMnSnk=";
              };
              fabric-api = pkgs.fetchurl { # do I need this?
                url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/sVqpGIb1/fabric-api-0.119.3%2B1.21.4.jar";
                sha256 = "sha256-ay3wDFI5TDmA+HE3/Wk37o10iItFyuZ9RwfMoCZ6bR8=";
              };
              BiomesOPlenty = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/HXF82T3G/versions/1hMDdKWQ/BiomesOPlenty-fabric-1.21.4-21.4.0.23.jar";
                sha256 = "sha256-n1OK5vDpVcFMEW6JgonTv7OJJgN62x4R04ZBDgxaMxg=";
              };
              GlitchCore = pkgs.fetchurl { # needed by biomesoplenty
                url = "https://mediafilez.forgecdn.net/files/6054/290/GlitchCore-fabric-1.21.4-2.3.0.4.jar";
                sha256 = "sha256-50xmoQwlDYEm+Vb3f3C6NfJgtpiXZcZuTdd94PyrPrw=";
              };
              TerraBlender = pkgs.fetchurl { # needed by biomesoplenty
                url = "https://mediafilez.forgecdn.net/files/6055/20/TerraBlender-fabric-1.21.4-4.3.0.2.jar";
                sha256 = "sha256-mBYDh/Qyw14DOHtxi4hVb52/Gs5Yjhi+SzNXBjYlQuQ=";
              };
            }
          );
        };
        files = {
          # Distant Horizons configuration with lodChunkRenderDistanceRadius = 512
          "config/DistantHorizons.toml" = pkgs.writeTextFile {
            name = "DistantHorizons.toml";
            text = ''
[client]
  [client.advanced]
    [client.advanced.graphics]
      [client.advanced.graphics.quality]
        # The radius of the mod's render distance. (measured in chunks)
        lodChunkRenderDistanceRadius = 1024
'';
          };
        };
      }; # End botw server

    };
  };
}

