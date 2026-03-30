{ inputs, ... }:
{
  flake.modules.nixos.luanti =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.nix-luanti.nixosModules.default ];

      nixpkgs.overlays = [ inputs.nix-luanti.overlays.default ];

      # Worlds are in /var/lib/luanti-<serverName>/world
      # To migrate a world:
      #   stop the service
      #   sudo rm -r /var/lib/luanti-<serverName>/world
      #   sudo install -o <user> -g luanti -d /var/lib/luanti-<serverName>/world
      #   sudo rsync -a --chown=<user>:luanti /path/to/old/world/ /var/lib/luanti-<serverName>/world/

      services.luanti = {
        enable = lib.mkDefault true;

        servers = with pkgs.luantiPackages; {
          anarchyMineclone2 = {
            game = games.mineclone2;
            port = 30000;
            openFirewall = true;
            config = {
              serverName        = "Yeshey mineclone server";
              serverDescription = "mine here";
              defaultGame       = "mineclone2";
              serverAnnounce    = false;
              enableDamage      = true;
              creativeMode      = false;
            };
          };

          anarchyMineclonia = {
            game = games.mineclonia;
            port = 30001;
            openFirewall = true;
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
    };
}