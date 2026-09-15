{ ... }:
{
  flake.modules.nixos.code-server =
    { pkgs, ... }:
    let
      internalPort = 2998;
      domain = "code.yeshey.dpdns.org";
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

      services.caddy.virtualHosts."${domain}" = {
        extraConfig = ''
          @tailnet remote_ip 100.64.0.0/10
          handle @tailnet {
            reverse_proxy 127.0.0.1:${toString internalPort}
          }
          handle {
            respond "Not found" 404
          }
        '';
      };

      networking.extraHosts = ''
        127.0.0.1 ${domain}
      '';
    };
}