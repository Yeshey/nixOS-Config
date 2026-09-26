{ ... }:
{
  flake.modules.nixos.pithagoras =
    { config, pkgs, lib, ... }:
    let
      profileDir = "/var/lib/pithagoras/browser-profile";
    in
    {
      sops.secrets.pithagoras_browser_password = {
        restartUnits = [
          "docker-pithagoras.service"
          "docker-pithagoras-browser.service"
        ];
      };

      # Portal uses password to connect to browser.
      sops.templates."pithagoras-browser-portal.env" = {
        mode = "0400";
        content = ''
          BROWSER_PASSWORD=${config.sops.placeholder.pithagoras_browser_password}
        '';
        restartUnits = [ "docker-pithagoras.service" ];
      };

      # LinuxServer Chromium uses PASSWORD for its web UI.
      sops.templates."pithagoras-browser-container.env" = {
        mode = "0400";
        content = ''
          PASSWORD=${config.sops.placeholder.pithagoras_browser_password}
        '';
        restartUnits = [ "docker-pithagoras-browser.service" ];
      };

      virtualisation.oci-containers.containers.pithagoras.extraOptions =
        lib.mkAfter [
          "--env-file=${config.sops.templates."pithagoras-browser-portal.env".path}"
        ];

      systemd.tmpfiles.rules = [
        "d ${profileDir} 0700 root root -"
      ];

      virtualisation.oci-containers.containers.pithagoras-browser = {
        image = "lscr.io/linuxserver/chromium:latest";

        volumes = [
          "${profileDir}:/config"
        ];

        environment = {
          PUID = "0";
          PGID = "0";
          TZ = "Europe/Lisbon";
          CUSTOM_USER = "agent";
          CUSTOM_PORT = "3010";
          CUSTOM_HTTPS_PORT = "3011";
          CHROME_CLI = "--remote-debugging-port=9222";
          RESTART_APP = "true";
        };

        environmentFiles = [
          config.sops.templates."pithagoras-browser-container.env".path
        ];

        extraOptions = [
          "--network=host"
          "--security-opt=seccomp=unconfined"
          "--shm-size=1g"
          "--pull=always"
        ];
      };

      systemd.services.docker-pithagoras-browser.unitConfig.RequiresMountsFor = [
        profileDir
        config.sops.templates."pithagoras-browser-container.env".path
      ];

      systemd.services.pithagoras-cdp-bridge = {
        description = "Browser CDP bridge for Pithagoras task containers";
        requires = [ "docker.service" ];
        after = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:9223,bind=172.17.0.1,reuseaddr,fork TCP:127.0.0.1:9222";
          Restart = "on-failure";
        };
      };

      networking.firewall.interfaces.docker0.allowedTCPPorts = [ 9223 ];

    };
}

# Browser login:
# username: agent
# password: sops value of pithagoras_browser_password