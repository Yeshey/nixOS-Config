{ ... }:
{
  flake.modules.nixos.code-server =
    { pkgs, ... }:
    let
      internalPort = 2998;
      caddyPort = 9444;
      hostname = "skyloft.ts";   # MagicDNS, never goes stale
      user = "yeshey";
    in
    {
      services.code-server = {
        enable = true;
        host = "127.0.0.1";
        port = internalPort;
        user = user;
        extraPackages = [ pkgs.openssl ];
        extraArguments = [
          "--auth=none"
          "--extensions-dir=/home/${user}/.local/share/code-server/extensions"
        ];
      };

      services.caddy.enable = true;
      services.caddy.virtualHosts."${hostname}:${toString caddyPort}" = {
        extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:${toString internalPort}
        '';
      };

      networking.firewall.allowedTCPPorts = [ caddyPort ];
    };
}