{ config, lib, pkgs, ... }:
let
  cfg = config.mySystem.autossh;
in
{
  options.mySystem.autossh = with lib; {
    enable = mkEnableOption "Enable autossh service for reverse SSH tunneling";

    remoteIP = mkOption {
      type = types.str;
      default = "143.47.53.175";
      description = "The remote server IP address for reverse SSH tunneling.";
    };

    remoteUser = mkOption {
      type = types.str;
      default = "yeshey";
      description = "The remote username used for the SSH connection.";
    };

    port = mkOption {
      type = types.port;
      default = 2222;
      description = "Remote port number to use for reverse SSH tunneling";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    services.autossh.sessions =
      [
        # check me out with `journalctl -f -u autossh-reverseProxy.service`
        {
          monitoringPort = 0; # Disable monitoring port
          name = "reverseProxy";
          user = cfg.remoteUser;
          extraArguments = 
            "-N -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -R ${toString cfg.port}:localhost:22 ${cfg.remoteUser}@${cfg.remoteIP}";
        }
      ];
  };
}
