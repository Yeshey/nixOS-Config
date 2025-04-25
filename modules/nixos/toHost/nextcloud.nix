{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.nextcloud;
in
{
  options.toHost.nextcloud = {
    enable = lib.mkEnableOption "nextcloud";
    port = lib.mkOption {
      type = lib.types.port;
      default = 85;
      description = "Port for the Nextcloud server to listen on";
    };
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = "Hostname for Nextcloud";
    };
  };

  config = lib.mkIf cfg.enable {
    # NextCloud
    services.nextcloud = {
      enable = true;
      # Remove specific version to prevent downgrade issues
      package = pkgs.nextcloud30;
      hostName = cfg.hostName;
      
      # Auto-update Nextcloud Apps
      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "05:00:00";
      
      # Object store configuration if needed
      config = {
        # Only include s3 configuration if you're actually using S3
        # objectstore.s3.port = cfg.port;
        adminpassFile = "${pkgs.writeText "adminpass" "test123"}"; # user: root, pass: test123
      };
    };

    services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
      listen = [{ 
        addr = "0.0.0.0";  # Listen on all interfaces instead of specific IP
        port = cfg.port;
      }];
    };

    networking.firewall.allowedTCPPorts = [
      cfg.port
      80  # Only include if needed
      443 # Only include if needed
    ];
  };
}