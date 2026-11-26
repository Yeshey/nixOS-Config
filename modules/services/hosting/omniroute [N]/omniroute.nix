{
  flake.modules.nixos.omniroute =
    { pkgs, lib, config, ... }:
    let
      port = 20128;
      dataDir = "/var/lib/omniroute";
    in
    {
      sops.secrets."omniroute-password" = { };
      sops.secrets."omniroute-ws-bridge-secret" = { };

      sops.templates."omniroute.env" = {
        content = ''
          INITIAL_PASSWORD=${config.sops.placeholder."omniroute-password"}
          OMNIROUTE_WS_BRIDGE_SECRET=${config.sops.placeholder."omniroute-ws-bridge-secret"}
        '';
        restartUnits = [ "omniroute.service" ];
      };

      users.users.omniroute = {
        isSystemUser = true;
        group = "omniroute";
      };
      users.groups.omniroute = { };

      # d: create. Z: recursively fix ownership (existing data was written by uid 1000 in docker)
      systemd.tmpfiles.rules = [
        "d ${dataDir}/data 0750 omniroute omniroute -"
        "Z ${dataDir}/data - omniroute omniroute -"
      ];

      systemd.services.omniroute = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          HOME = dataDir;
          DATA_DIR = "${dataDir}/data";
          PORT = toString port;
          HOSTNAME = "127.0.0.1"; # VERIFY: must stay loopback-only
          REQUIRE_API_KEY = "true";
          NEXT_PUBLIC_BASE_URL = "https://skyloft.tailb6874b.ts.net:8446";
          AUTH_COOKIE_SECURE = "true";
        };
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.unstable-small.omniroute} serve"; # VERIFY subcommand
          EnvironmentFile = config.sops.templates."omniroute.env".path;
          User = "omniroute";
          Group = "omniroute";
          Restart = "on-failure";
          RestartSec = "5s";
          TimeoutStopSec = 60; # let SQLite checkpoint WAL
        };
      };
    };
}