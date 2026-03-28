let
  optName = "autossh-reverse-proxy";
in
{
  flake.modules.nixos.autossh-reverse-proxy =
    { lib, config, ... }:
    {
      options.autossh-reverse-proxy = {
        enable = lib.mkEnableOption "autossh reverse SSH tunnel";

        remoteIP = lib.mkOption {
          type    = lib.types.str;
          default = "143.47.53.175";
          description = "Remote server IP for reverse SSH tunneling.";
        };

        remoteUser = lib.mkOption {
          type    = lib.types.str;
          default = "yeshey";
          description = "Username on the remote server.";
        };

        port = lib.mkOption {
          type    = lib.types.port;
          default = 2222;
          description = "Remote port to forward back to localhost:22.";
        };
      };

      config = lib.mkIf config.autossh-reverse-proxy.enable {
        services.autossh.sessions = [{
          # check with: journalctl -f -u autossh-reverseProxy.service
          monitoringPort = 0; # disable monitoring port
          name           = "reverseProxy";
          user           = config.autossh-reverse-proxy.remoteUser;
          extraArguments =
            "-N -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3 " +
            "-R ${toString config.autossh-reverse-proxy.port}:localhost:22 " +
            "${config.autossh-reverse-proxy.remoteUser}@${config.autossh-reverse-proxy.remoteIP}";
        }];
      };
    };

  flake.modules.homeManager.autossh-reverse-proxy =
    { pkgs, lib, config, ... }:
    {
      options.autossh-reverse-proxy = {
        enable = lib.mkEnableOption "autossh reverse SSH tunnel (user service)";

        remoteIP = lib.mkOption {
          type    = lib.types.str;
          default = "143.47.53.175";
        };

        remoteUser = lib.mkOption {
          type    = lib.types.str;
          default = "yeshey";
        };

        port = lib.mkOption {
          type    = lib.types.port;
          default = 2222;
        };
      };

      config = lib.mkIf config.autossh-reverse-proxy.enable {
        home.packages = [ pkgs.autossh ];

        # check with: systemctl --user status autossh-reverse-proxy
        systemd.user.services.${optName} = {
          Unit = {
            Description = "autossh reverse proxy → ${config.autossh-reverse-proxy.remoteIP}";
            After    = [ "network-online.target" ];
            Wants    = [ "network-online.target" ];
          };

          Service = {
            Environment = [ "AUTOSSH_GATETIME=0" ];
            ExecStart =
              let
                args = lib.escapeShellArgs [
                  "-M" "0"
                  "-N"
                  "-o" "ExitOnForwardFailure=yes"
                  "-o" "ServerAliveInterval=60"
                  "-o" "ServerAliveCountMax=3"
                  "-R" "${toString config.autossh-reverse-proxy.port}:localhost:22"
                  "${config.autossh-reverse-proxy.remoteUser}@${config.autossh-reverse-proxy.remoteIP}"
                ];
              in "${pkgs.autossh}/bin/autossh ${args}";
            Restart    = "always";
            RestartSec = 10;
          };

          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}