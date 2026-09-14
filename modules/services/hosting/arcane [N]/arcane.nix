{
  flake.modules.nixos.arcane =
    { pkgs, ... }:
    let
      port = 3552;
      dataDir = "/var/lib/arcane";
      vpnAddr = "10.8.0.1";
    in
    {
      systemd.services."docker-arcane-mgr" = {
        description = "Generate persistent secrets/data dir for arcane";
        wantedBy = [ "multi-user.target" "docker-arcane.service" ];
        before = [ "docker-arcane.service" ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -eu
          mkdir -p ${dataDir}/data
          ENV=${dataDir}/secrets.env
          if [ ! -f "$ENV" ]; then
            umask 077
            {
              echo "JWT_SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 32)"
              echo "ENCRYPTION_KEY=$(${pkgs.openssl}/bin/openssl rand -hex 32)"
            } > "$ENV"
          fi
        '';
      };

      virtualisation.oci-containers.containers.arcane = {
        image = "ghcr.io/getarcaneapp/arcane:latest";
        autoStart = true;
        extraOptions = [ "--pull=always" ];
        ports = [ "${toString port}:${toString port}" ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "${dataDir}/data:/app/data"
        ];
        environmentFiles = [ "${dataDir}/secrets.env" ];
        environment = {
          APP_URL = "http://${vpnAddr}:${toString port}";
          PUID = "1000";
          PGID = "1000";
        };
      };

      systemd.services."docker-arcane" = {
        after = [ "remote-fs.target" "network-online.target" "docker-arcane-mgr.service" ];
        wants = [ "remote-fs.target" "network-online.target" ];
        requires = [ "docker-arcane-mgr.service" ];
      };

      networking.firewall.allowedTCPPorts = [ port ];
    };
}