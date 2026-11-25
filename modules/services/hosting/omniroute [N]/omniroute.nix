{
  flake.modules.nixos.omniroute =
    { pkgs, config, ... }:
    let
      port = 20128;
      dataDir = "/var/lib/omniroute";
      image = "docker.io/cheaperinference/omniroute:latest";
    in
    {
      sops.secrets."omniroute-password" = { };
      sops.secrets."omniroute-ws-bridge-secret" = { };

      sops.templates."omniroute.env" = {
        content = ''
          INITIAL_PASSWORD=${config.sops.placeholder."omniroute-password"}
          OMNIROUTE_WS_BRIDGE_SECRET=${config.sops.placeholder."omniroute-ws-bridge-secret"}
        '';
        restartUnits = [ "docker-omniroute.service" ];
      };

      # image runs as uid 1000 (user "node")
      systemd.tmpfiles.rules = [ "d ${dataDir}/data 0750 1000 1000 -" ];

      virtualisation.oci-containers.containers.omniroute = {
        inherit image;
        autoStart = true;
        extraOptions = [ "--pull=always" "--stop-timeout=40" ];
        ports = [ "127.0.0.1:${toString port}:${toString port}" ];
        volumes = [ "${dataDir}/data:/app/data" ];
        environmentFiles = [ config.sops.templates."omniroute.env".path ];
        environment = {
          REQUIRE_API_KEY = "true";
          NEXT_PUBLIC_BASE_URL = "https://skyloft.tailb6874b.ts.net:8445";
          AUTH_COOKIE_SECURE = "true";
        };
      };

      systemd.services."docker-omniroute" = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
      };

      # Daily: pull, restart only if image changed
      systemd.services."omniroute-update" = {
        path = [ pkgs.docker ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -eu
          old=$(docker image inspect -f '{{.Id}}' ${image} 2>/dev/null || true)
          docker pull ${image}
          new=$(docker image inspect -f '{{.Id}}' ${image})
          if [ "$old" != "$new" ]; then
            systemctl restart docker-omniroute.service
          fi
        '';
      };

      systemd.timers."omniroute-update" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };
}