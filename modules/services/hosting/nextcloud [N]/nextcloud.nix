# import this and then change what you need with for example:
# services.nextcloud.hostName = lib.mkForce "mynextcloud.example.com"

{ ... }:
{
  flake.modules.nixos.nextcloud =
    { pkgs, config, lib, ... }:
    let
      port = 85;
      hostName = "localhost";
    in
    {
      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud33;
        hostName = hostName;
        autoUpdateApps.enable = true;
        autoUpdateApps.startAt = "05:00:00";
        config = {
          adminpassFile = "${pkgs.writeText "adminpass" "test123"}"; # user: root, pass: test123
          dbtype = "mysql";
        };
      };

      services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
        listen = [{ addr = "0.0.0.0"; port = port; }];
      };

      networking.firewall.allowedTCPPorts = [ port 80 443 ];
    };
}