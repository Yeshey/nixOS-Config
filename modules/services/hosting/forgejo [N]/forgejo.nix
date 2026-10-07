{
  flake.modules.nixos.forgejo =
    { config, lib, pkgs, ... }:
    let
      port = 3000;
      httpsPort = 8443;
      hostname = "skyloft.tailb6874b.ts.net";
      tailscale = lib.getExe config.services.tailscale.package;

      serveConfig = pkgs.writeText "forgejo-tailscale-serve.json" (
        builtins.toJSON {
          TCP."${toString httpsPort}".HTTPS = true;
          Web."${hostname}:${toString httpsPort}".Handlers."/" = {
            Proxy = "http://127.0.0.1:${toString port}";
          };
        }
      );

      applyServeConfig = pkgs.writeShellScript "apply-forgejo-serve" ''
        exec ${tailscale} serve set-raw < ${serveConfig}
      '';
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

      services.tailscale.serve = {
        enable = true;
        configFile = serveConfig;
      };

      # Raw node configuration requires set-raw on Tailscale 1.98.10.
      # Reuse the unit provided by services.tailscale.serve.
      systemd.services.tailscale-serve = {
        after = [ "forgejo.service" ];
        wants = [ "forgejo.service" ];
        serviceConfig.ExecStart = lib.mkForce "${applyServeConfig}";
      };

      environment.systemPackages = [ pkgs.forgejo-lts ];
      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];
    };
}