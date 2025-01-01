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
    scheduele = lib.mkOption {
      type = lib.types.str;
      description = "Frequency of tests. Runs at the start of every hour by default";
      example = "*/10 * * * *"; # Runs every 10 minutes
      default = "0 * * * *";
    };
    unencryptedPort = lib.mkOption {
      type = lib.types.str;
      description = "Unencrypted Port";
      example = "8081"; # Runs every 10 minutes
      default = "8881";
    };
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
          "${cfg.unencryptedPort}:80"
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
          SPEEDTEST_SCHEDULE = cfg.scheduele;
          AUTH = "false";
          DISPLAY_TIMEZONE = "Europe/Lisbon";
          APP_TIMEZONE = "Europe/Lisbon";
        };
        #restartPolicy = "unless-stopped";
      };
    };
  systemd.services.speedtest-tracker-mgr = {
    wantedBy = [ "multi-user.target" "podman-speedtest_tracker.service" ];
    script = ''
      WORKING_DIR="/opt/docker/speedtest"
      SSL_DIR="$WORKING_DIR/ssl-keys"

      echo "Ensuring working directory exists..."
      if [ ! -d $WORKING_DIR ]; then
        echo "Directory does not exist, creating..."
        mkdir -p $WORKING_DIR
      else
        echo "Directory already exists."
      fi

      echo "Ensuring SSL keys directory exists..."
      if [ ! -d $SSL_DIR ]; then
        echo "SSL keys directory does not exist, creating..."
        mkdir -p $SSL_DIR
      else
        echo "SSL keys directory already exists."
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };



    # makeDesktopItem https://discourse.nixos.org/t/proper-icon-when-using-makedesktopitem/32026
    # Syncthing desktop shortcut
    environment.systemPackages =
      with pkgs;
      let
        syncthingWeb = makeDesktopItem {
          name = "Speedtest Tracker";
          desktopName = "Speedtest Tracker";
          genericName = "Speedtest Tracker";
          exec = ''xdg-open "http://localhost:${cfg.unencryptedPort}/admin#"'';
          icon = "firefox";
          categories = [
            "GTK"
            "X-WebApps"
          ];
          mimeTypes = [
            "text/html"
            "text/xml"
            "application/xhtml_xml"
          ];
        };
      in
      [
        xdg-utils
        syncthingWeb
      ];

  };
}
