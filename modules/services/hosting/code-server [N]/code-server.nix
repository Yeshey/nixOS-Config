{
  flake.modules.nixos.code-server =
    { pkgs, ... }:
    let 
      externalPort = 2998;
      hostname = "143.47.53.175";
      user = "yeshey";
    in 
        {
      services.code-server = {
        enable = true;
        # package = pkgs.code-server;
        host = "0.0.0.0";
        port = externalPort;
        user = user;
        extraPackages = [pkgs.openssl]; 
        extraArguments = [
          "--auth=none"
          "--extensions-dir=/home/${user}/.vscode-oss/extensions"
          "--cert"
        ];
      };
      networking.firewall.allowedTCPPorts = [
        externalPort
      ];
    };
}