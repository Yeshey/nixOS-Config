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
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

  options.toHost.minecraft = {
    enable = (lib.mkEnableOption "minecraft");
  };

  config = lib.mkIf cfg.enable {

    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

    services.minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;
      servers.pixelmon = {
        serverProperties ={
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
        package = pkgs.fabricServers.fabric-1_21_1; #.override { loaderVersion = "0.16.10"; }; # Specific fabric loader version

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
