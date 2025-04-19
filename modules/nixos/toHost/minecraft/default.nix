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
      servers.pixelmon = {
        # options specific for pixelmon?
        jvmOpts = "-Xms6144M -Xmx8192M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=50 -XX:G1MaxNewSizePercent=80 -XX:G1MixedGCLiveThresholdPercent=50 -XX:+ParallelRefProcEnabled -XX:+AlwaysPreTouch -XX:+PerfDisableSharedMem";
        # connect to terminal with sudo tmux -S /run/minecraft/pixelmon.sock attach
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
          "query.port"=44335;
          "online-mode"=false;
        };
        enable = true;

        # Specify the custom minecraft server package
        #package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version
        package = pkgs.forgeServers.${serverVersion}.override { # forge for minecraft 1.20.1
          loaderVersion = forgeVersion;
          jre_headless = pkgs_graalvm.graalvm-ce;
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


      };
    };
  };
}
