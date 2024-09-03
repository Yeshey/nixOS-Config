{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.speedtest-tracker;
in
{
  options.mySystem.speedtest-tracker = {
    enable = lib.mkEnableOption "speedtest-tracker";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable)  {

    # journalctl -fu podman-speedtest_tracker.service
    # usually in /opt/docker (need to craeate folders manually?)
    # see here: http://localhost:8081/admin
    # default admin login: https://docs.speedtest-tracker.dev/security/authentication
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.containers = {
      speedtest_tracker = {
        image = "lscr.io/linuxserver/speedtest-tracker:0.20.6";
        volumes = [
          "/opt/docker/speedtest:/config"
          "/opt/docker/speedtest//ssl-keys:/config/keys"
        ];
        ports = [
          "8081:80"
          "8443:443"
        ];
        autoStart = true;
        extraOptions = [ "--rm" "--pull=always" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          APP_KEY = "base64:tdRUioeLWq3KJup4Hr8dBwiYrb/4ICm60TbnAez61aY=";
          APP_URL = "http://localhost";
          DB_CONNECTION = "sqlite";
          SPEEDTEST_SCHEDULE = "*/10 * * * *"; # Runs every 10 minutes
          AUTH = "false";
        };
        #restartPolicy = "unless-stopped";
      };
    };

  };
}
