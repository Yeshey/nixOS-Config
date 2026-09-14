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
            DOMAIN = "forgejo.local"; # or your host
            ROOT_URL = "http://10.8.0.1:3000/";
            HTTP_PORT = port;
          };
          actions.ENABLED = true; # off by default — needed for Forgejo Actions
        };
      };
      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];

    };
}