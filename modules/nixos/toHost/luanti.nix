{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (pkgs) system;
  nix-luanti = inputs.nix-luanti.packages.${system};
  cfg = config.toHost.luanti;
in
{
  imports = [ inputs.nix-luanti.nixosModules.default ];

  options.toHost.luanti = {
    enable = lib.mkEnableOption "luanti";
  };

  config = lib.mkIf cfg.enable {

    nixpkgs.overlays = [ # needed while minetest is not called luanti
      (final: prev: {
        luanti-server = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.luanti-server;
        # If minetestserver also needs unstable:
        # minetestserver = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.minetestserver;
      })
      (final: prev: { # needed for multiple instances on different ports (see ://github.com/NixOS/nixpkgs/issues/383670#issuecomment-2672619706)
        minetest = prev.minetest.overrideAttrs (oldAttrs: {
          cmakeFlags = let
            # Filter out any existing flags containing "ENABLE_PROMETHEUS"
            filtered = prev.lib.filter (flag: !(prev.lib.strings.hasInfix "ENABLE_PROMETHEUS" flag)) oldAttrs.cmakeFlags;
          in
            filtered ++ [ "-DENABLE_PROMETHEUS=OFF" ];
        });
      })
    ];

    # Worlds are in /var/lib/luanti-<serverName>/world
    # You can copy worlds into there with the right premissions with:
    # stop the service, then start it in the end again
    # see user of the world: `sudo ls -la /var/lib/luanti-<serverName>/`
    # delete the folder `sudo rm -r /var/lib/luanti-<serverName>/world`, create it again: ``sudo install -o <username> -g luanti -d /var/lib/luanti-<serverName>/worl`
    # move files into there `sudo rsync -a --chown=<user>:luanti /var/lib/minetest/.minetest/worlds/MinecloniaFirstServerAnarchy/ /var/lib/luanti-<serverName>/world/`

    # Enable the luanti service with two servers
    services.luanti = {
      enable = true;

      servers = with nix-luanti; {
        #package = pkgs.minetestserver;
        # First server: MineClone2 on port 30000
        anarchyMineclone2 = {
          game = games.mineclone2;
          port = 30000;
          # Per-server minetest config
          config = {
            serverName        = "Yeshey mineclone server";
            serverDescription = "mine here";
            defaultGame       = "mineclone2";
            serverAnnounce    = false;
            enableDamage      = true;
            creativeMode      = false;
          };
        };

        # Second server: MineClonia on port 30001
        anarchyMineclonia = {
          #package = pkgs.minetestserver;
          game = games.mineclonia;
          port = 30001;
          # Per-server minetest config
          config = {
            serverName        = "Yeshey mineclonia server";
            serverDescription = "mine here";
            defaultGame       = "mineclonia";
            serverAnnounce    = false;
            enableDamage      = true;
            creativeMode      = false;
          };
        };
      };
    };

    environment.persistence."/persistent" = {
      directories = [
        { directory = "/var/lib/luanti-anarchyMineclone2"; user = "luanti-anarchyMineclone2"; group = "luanti"; mode = "u=rwx,g=rx,o="; }
        { directory = "/var/lib/luanti-anarchyMineclonia"; user = "luanti-anarchyMineclonia"; group = "luanti"; mode = "u=rwx,g=rx,o="; }
      ];
    };

    # Open both ports in the firewall, only UDP needed
    networking.firewall.allowedUDPPorts = [ 30000 30001 ];
  };
}
