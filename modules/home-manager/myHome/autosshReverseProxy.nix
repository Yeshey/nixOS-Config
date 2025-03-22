{ config, lib, pkgs, ... }:
let
  cfg = config.myHome.autosshReverseProxy;
in
{

  options.myHome.autosshReverseProxy = with lib; {
    enable = mkEnableOption "autosshReverseProxy";

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

  config = lib.mkIf cfg.enable {
    # Ensure autossh is installed in the home environment.
    home.packages = [ pkgs.autossh ];

    systemd.user.services.autossh-reverse-proxy = {
      Unit = {
        Description = "Autossh reverse proxy to ${cfg.remoteIP}";
        After = [ "network-online.target" ];
      };

      Service = {
        Environment = [ "AUTOSSH_GATETIME=0" ];
        ExecStart = let
          args = [
            "-M" "0"           # Disable monitoring port
            "-N"               # No remote command execution
            "-o ExitOnForwardFailure=yes"
            "-o ServerAliveInterval=60"
            "-o ServerAliveCountMax=3"
            "-R ${toString cfg.port}:localhost:22"
            "${cfg.remoteUser}@${cfg.remoteIP}"
          ];
        in "${pkgs.autossh}/bin/autossh ${lib.escapeShellArgs args}";
        Restart = "always";
        RestartSec = 10;
      };

      Install.WantedBy = [ "default.target" ];
    };

  };
}
