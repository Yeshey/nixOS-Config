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
        serverProperties = {
          server-port = 44332;
          server-portv6 = 44333;
          difficulty = 1;
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
        package = pkgs.forgeServers.${serverVersion}.override {
          loaderVersion = forgeVersion;
          jre_headless = pkgs_graalvm.graalvm-ce;
        };

        # symlinks = {
        #   mods = pkgs.linkFarmFromDrvs "mods" (
        #     builtins.attrValues {
        #       Fabric-API = pkgs.fetchurl {
        #         url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/9YVrKY0Z/fabric-api-0.115.0%2B1.21.1.jar";
        #         sha512 = "e5f3c3431b96b281300dd118ee523379ff6a774c0e864eab8d159af32e5425c915f8664b1";
        #       };
        #       Backpacks = pkgs.fetchurl {
        #         url = "https://cdn.modrinth.com/data/MGcd6kTf/versions/Ci0F49X1/1.2.1-backpacks_mod-1.21.2-1.21.3.jar";
        #         sha512 = "6efcff5ded172d469ddf2bb16441b6c8de5337cc623b6cb579e975cf187af0b79291";
        #       };
        #     }
        #   );
        # };

        symlinks = {
          mods = pkgs.linkFarmFromDrvs "mods" (
            builtins.attrValues {
              luckyBlock = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4817/267/lucky-block-forge-1.20.1-13.0.jar";
                # replace with the real hash:
                sha256 = "sha256-wQHdMm5e1CHQNz7sBlBUz1lyE09jnzhT01VC53ouGEw=";
              };
              Pixelmon = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4782/28/Pixelmon-1.20.1-9.2.3-universal.jar";
                sha256 = "sha256-jyd39afNK1/EisP1Ux1DSvQSDH1ArcmSnVo3N8QEJGo=";
              };
              ProjectE = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/4901/949/ProjectE-1.20.1-PE1.0.1.jar";
                sha256 = "sha256-9R84flYwfnzaJpFcoMeJdg2F6XqLQLi/oJiL5mNx0Bg=";
              };
              configuredForge = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5180/900/configured-forge-1.20.1-2.2.3.jar";
                sha256 = "sha256-Bdzt3VeCX5ERNckpUE7zILdZU9BefckY26WKBXTlMV8=";
              };
              journeymap = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/5789/363/journeymap-1.20.1-5.10.3-forge.jar";
                sha256 = "sha256-iyZ5t7SIHgqkMP0kNF6kRt6Rn6+KRb0qcdN8fo/2rh4=";
              };
              jei = pkgs.fetchurl {
                url = "https://mediafilez.forgecdn.net/files/6075/247/jei-1.20.1-forge-15.20.0.106.jar";
                sha256 = "sha256-49jyxAKPpDE2jUK94luSsiEL3dLh+1mpMtDCzGLdNYc=";
              };
            }
          );
        };


        #package = pkgs.forgeServers."1.16.5-36.2.8";
        # symlinks = {
        #   mods = pkgs.linkFarmFromDrvs "mods" (
        #     builtins.attrValues {
        #       Fabric-API = pkgs.fetchurl {
        #         url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/9YVrKY0Z/fabric-api-0.115.0%2B1.21.1.jar";
        #         sha512 = "e5f3c3431b96b281300dd118ee523379ff6a774c0e864eab8d159af32e5425c915f8664b1";
        #       };
        #       Backpacks = pkgs.fetchurl {
        #         url = "https://cdn.modrinth.com/data/MGcd6kTf/versions/Ci0F49X1/1.2.1-backpacks_mod-1.21.2-1.21.3.jar";
        #         sha512 = "6efcff5ded172d469ddf2bb16441b6c8de5337cc623b6cb579e975cf187af0b79291";
        #       };
        #     }
        #   );
        # };
      };
    };


    # environment.systemPackages = with pkgs; [
    #   (callPackage ./../../pkgs/playit-cli.nix { }) # TODO ???
    #   jdk17
    # ];

    # run playit-cli launch ./../main_server_config.toml
    # in here: /home/yeshey/PersonalFiles/Servers/minecraft/Valhelsia5/server
    # The address is quotes-sara.at.ply.gg:18976
    # TODO make a service and add playit.cli to nixpkgs?
  };
}
