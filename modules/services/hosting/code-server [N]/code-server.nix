{
  flake.modules.nixos.code-server =
    { pkgs, ... }:
    let
      internalPort = 2998;
      caddyPort = 9444;
      vpnAddr = "10.8.0.1";
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
          "--extensions-dir=/home/${user}/.local/share/code-server/extensions"  # separate from home-manager's vscodium dir
        ];
      };

      services.caddy.enable = true;
      services.caddy.virtualHosts."${vpnAddr}:${toString caddyPort}" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:${toString internalPort}
        '';
      };

      networking.firewall.allowedTCPPorts = [ caddyPort ];
    };
}