{
  flake.modules.nixos.forgejo =
    { pkgs, ... }:
    let
      port = 3000;
      httpsPort = 8443;
      hostname = "skyloft.tailb6874b.ts.net";
    in
    {
      services.forgejo = {
        enable = true;
        database.type = "postgres";
        settings = {
          server = {
            DOMAIN = hostname;
            ROOT_URL = "https://${hostname}:${toString httpsPort}/";
            HTTP_PORT = port;
          };
          actions.ENABLED = true;
        };
      };

      environment.systemPackages = [ pkgs.forgejo-lts ];
      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];
    };
}