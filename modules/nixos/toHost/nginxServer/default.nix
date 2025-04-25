{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.nginxServer;
in
{
  imports = [
    # ...
  ];

  options.toHost.nginxServer = {
    enable = lib.mkEnableOption "nginxServer";
    port = lib.mkOption {
      type = lib.types.port;
      default = 7843;
      description = "Port for the nginx server to listen on";
    };
    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address for nginx to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts."anything" = {
        root = ./src;
        listen = [
          {
            port = cfg.port;
            addr = cfg.listenAddress;
          }
        ];
      };
    };
    
    security.acme = {
      acceptTerms = true;
      defaults.email = "yesheysangpo@gmail.com";
    };
    
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}