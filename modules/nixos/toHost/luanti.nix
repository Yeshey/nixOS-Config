{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.toHost.luanti;
in
{
  imports = [ inputs.nix-luanti.nixosModules.default ];

  options.toHost.luanti = {
    enable = lib.mkEnableOption "luanti";
  };

  config = lib.mkIf cfg.enable {

    # still needed?
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

    # Enable the luanti service with two servers
    services.luanti = {
      enable = true;

      servers = with nix-luanti; {
        # First server: MineClone2 on port 30000
        mineclone2 = {
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
        mineclonia = {
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
