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

    nixpkgs.overlays = [
      (final: prev: {
        luanti-server = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.luanti-server;
        # If minetestserver also needs unstable:
        # minetestserver = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.minetestserver;
      })
    ];

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


    # Open both ports in the firewall
    networking.firewall.allowedUDPPorts = [ 30000 30001 ];
  };
}
