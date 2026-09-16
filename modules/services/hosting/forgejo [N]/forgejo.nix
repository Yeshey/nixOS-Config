{
  flake.modules.nixos.forgejo =
    let
      port = 3000;
    in
    {
      services.forgejo = {
        enable = true;
        database.type = "postgres";
        settings = {
          server = {
            DOMAIN = "skyloft.tailb6874b.ts.net";
            ROOT_URL = "http://skyloft.tailb6874b.ts.net:${toString port}/";
            HTTP_PORT = port;
          };
          actions.ENABLED = true;
        };
      };
      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];
    };
}