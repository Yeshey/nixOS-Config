{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.overleaf;
in
{
  options.toHost.overleaf = {
    enable = lib.mkEnableOption "Overleaf Service";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/docker/overleaf";
      description = "Path to store Overleaf persistent data";
    };
    port = lib.mkOption {
      type = lib.types.str;
      default = "8093";
      description = "Host port to expose Overleaf web interface";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # NOTHING OF THIS WORKED, you might as well wait for them to package overleaf in nixOS.

    # to make it work with docker follow: https://github.com/overleaf/overleaf/issues/881 (and you can look at https://blog.znjoa.com/2024/11/24/installing-overleaf-community-edition-on-raspberry-pi/ for more details on the commands)

    #  virtualisation.podman.enable = true;
      
    #   virtualisation.oci-containers.containers = {
    #     overleaf = {
    #       image = "abhilesh7/overleaf-arm:latest";
    #       autoStart = true;
    #       ports = [ "${cfg.port}:80" ];
    #       volumes = [ "${cfg.dataDir}:/var/lib/overleaf-data" ];
    #       extraOptions = [ "--pull=always" ];
    #     };
    #   };

    #   systemd.services.overleaf-dir-mgr = {
    #     wantedBy = [ "multi-user.target" ];
    #     script = ''
    #       if [ ! -d "${cfg.dataDir}" ]; then
    #         mkdir -p "${cfg.dataDir}"
    #         chmod 777 "${cfg.dataDir}"
    #       fi
    #     '';
    #     serviceConfig = {
    #       Type = "oneshot";
    #       User = "root";
    #     };
    #   };

    #   systemd.services.podman-overleaf = {
    #     requires = [ "overleaf-dir-mgr.service" ];
    #     after = [ "overleaf-dir-mgr.service" ];
    #   };

    #   environment.systemPackages = with pkgs; [
    #     (makeDesktopItem {
    #       name = "Overleaf";
    #       desktopName = "Overleaf";
    #       genericName = "LaTeX Editor";
    #       exec = "xdg-open http://localhost:${cfg.port}";
    #       icon = "firefox";
    #       categories = [ "Office" "X-WebApps" ];
    #     })
    #   ];
    # };

    # networking.firewall.enable = false;

    # Runtime podman
    # virtualisation.podman = {
    #   enable = true;
    #   autoPrune.enable = true;
    #   dockerCompat = lib.mkForce true;
    # };
    # virtualisation.oci-containers.backend = "podman";

    # Runtime docker
    # boot.binfmt.registrations.x86_64-linux.fixBinary = true;

    # virtualisation.docker = {
    #   enable = true;
    #   autoPrune.enable = true;
    #   extraOptions = "--add-runtime qemu-x86_64=${pkgs.qemu}/bin/qemu-x86_64-static";
    # };
    # virtualisation.oci-containers.backend = "docker";

    # # Containers
    # virtualisation.oci-containers.containers."mongo" = {
    #   image = "mongo:6.0";
    #   environment = {
    #     "MONGO_INITDB_DATABASE" = "sharelatex";
    #   };
    #   volumes = [
    #     "/home/yeshey/Downloads/overleaf/bin/shared/mongodb-init-replica-set.js:/docker-entrypoint-initdb.d/mongodb-init-replica-set.js:rw"
    #     "/home/yeshey/mongo_data:/data/db:rw"
    #   ];
    #   cmd = [ "--replSet" "overleaf" ];
    #   log-driver = "journald";
    #   extraOptions = [
    #     "--add-host=mongo:127.0.0.1"
    #     "--health-cmd=echo 'db.stats().ok' | mongosh localhost:27017/test --quiet"
    #     "--health-interval=10s"
    #     "--health-retries=5"
    #     "--health-timeout=10s"
    #     "--network-alias=mongo"
    #     "--network=overleaf_default"
    #   ];
    # };
    # systemd.services."docker-mongo" = {
    #   serviceConfig = {
    #     Restart = lib.mkOverride 90 "always";
    #     RestartMaxDelaySec = lib.mkOverride 90 "1m";
    #     RestartSec = lib.mkOverride 90 "100ms";
    #     RestartSteps = lib.mkOverride 90 9;
    #   };
    #   after = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   requires = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   partOf = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    #   wantedBy = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    # };
    # virtualisation.oci-containers.containers."redis" = {
    #   image = "redis:6.2";
    #   volumes = [
    #     "/home/yeshey/redis_data:/data:rw"
    #   ];
    #   log-driver = "journald";
    #   extraOptions = [
    #     "--network-alias=redis"
    #     "--network=overleaf_default"
    #   ];
    # };
    # systemd.services."docker-redis" = {
    #   serviceConfig = {
    #     Restart = lib.mkOverride 90 "always";
    #     RestartMaxDelaySec = lib.mkOverride 90 "1m";
    #     RestartSec = lib.mkOverride 90 "100ms";
    #     RestartSteps = lib.mkOverride 90 9;
    #   };
    #   after = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   requires = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   partOf = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    #   wantedBy = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    # };
    # virtualisation.oci-containers.containers."sharelatex" = {
    #   image = "sharelatex/sharelatex";
    #   # platform = "linux/amd64"; # Explicit architecture
    #   environment = {
    #     "EMAIL_CONFIRMATION_DISABLED" = "true";
    #     "ENABLED_LINKED_FILE_TYPES" = "project_file,project_output_file";
    #     "ENABLE_CONVERSIONS" = "true";
    #     "OVERLEAF_APP_NAME" = "Overleaf Community Edition";
    #     "OVERLEAF_MONGO_URL" = "mongodb://mongo/sharelatex";
    #     "OVERLEAF_REDIS_HOST" = "redis";
    #     "REDIS_HOST" = "redis";
    #     "SANDBOXED_COMPILES" = "true";
    #     "SANDBOXED_COMPILES_HOST_DIR_COMPILES" = "/home/user/sharelatex_data/data/compiles";
    #     "SANDBOXED_COMPILES_HOST_DIR_OUTPUT" = "/home/user/sharelatex_data/data/output";
    #     "SANDBOXED_COMPILES_SIBLING_CONTAINERS" = "true";
    #   };
    #   volumes = [
    #     "/home/yeshey/sharelatex_data:/var/lib/overleaf:rw"
    #   ];
    #   ports = [
    #     "8094:80/tcp"
    #   ];
    #   dependsOn = [
    #     "mongo"
    #     "redis"
    #   ];
    #   log-driver = "journald";
    #   extraOptions = [
    #     "--platform=linux/amd64"
    #     "--network-alias=sharelatex"
    #     "--network=overleaf_default"
    #   ];
    # };
    # systemd.services."docker-sharelatex" = {
    #   serviceConfig = {
    #     Restart = lib.mkOverride 90 "always";
    #     RestartMaxDelaySec = lib.mkOverride 90 "1m";
    #     RestartSec = lib.mkOverride 90 "100ms";
    #     RestartSteps = lib.mkOverride 90 9;
    #   };
    #   after = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   requires = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   partOf = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    #   wantedBy = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    # };

    # # Networks
    # systemd.services."docker-network-overleaf_default" = {
    #   path = [ pkgs.docker ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     ExecStop = "docker network rm -f overleaf_default";
    #   };
    #   script = ''
    #     docker network inspect overleaf_default || docker network create overleaf_default
    #   '';
    #   partOf = [ "docker-compose-overleaf-root.target" ];
    #   wantedBy = [ "docker-compose-overleaf-root.target" ];
    # };

    # # Root service
    # # When started, this will automatically create all resources and start
    # # the containers. When stopped, this will teardown all resources.
    # systemd.targets."docker-compose-overleaf-root" = {
    #   unitConfig = {
    #     Description = "Root target generated by compose2nix.";
    #   };
    #   wantedBy = [ "multi-user.target" ];
    # };

  };
}
