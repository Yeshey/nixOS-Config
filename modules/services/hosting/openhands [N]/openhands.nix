{ inputs, ... }:
{
  flake.modules.nixos.openhands =
    { pkgs, ... }:
    let
      port = 8000;
      home = "/home/yeshey";
      openhandsDir = "${home}/.openhands";
      projectsDir = "${home}/openhands-projects";
      litellmPort = 4000; # must match modules/services/hosting/litellm [N]/litellm.nix
    in
    {
      virtualisation.docker.enable = true;
      virtualisation.oci-containers.backend = "docker";

      virtualisation.oci-containers.containers.openhands = {
        image = "ghcr.io/openhands/agent-canvas:1.16.0";
        autoStart = true;
        extraOptions = [
          "--rm"
          "--pull=always"
          "--add-host=host.docker.internal:host-gateway"
        ];
        ports = [ "0.0.0.0:${toString port}:${toString port}" ];
        volumes = [
          "${openhandsDir}:/home/openhands/.openhands"
          "${projectsDir}:/projects"
        ];
      };

      systemd.services.docker-openhands = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        requires = [ "network-online.target" ];
      };

      systemd.services.openhands-mgr = {
        wantedBy = [ "multi-user.target" "docker-openhands.service" ];
        script = ''
          for d in "${openhandsDir}" "${projectsDir}"; do
            echo "Ensuring $d exists..."
            mkdir -p "$d"
            chmod -R 0777 "$d"
          done
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };

      networking.firewall.allowedTCPPorts = [ port ];

      environment.systemPackages =
        let
          openhandsWeb = pkgs.makeDesktopItem {
            name = "OpenHands";
            desktopName = "OpenHands";
            genericName = "OpenHands";
            exec = ''xdg-open "http://localhost:${toString port}/canvas"'';
            icon = "firefox";
            categories = [ "GTK" "X-WebApps" ];
            mimeTypes = [ "text/html" "text/xml" "application/xhtml_xml" ];
          };
        in
        [ pkgs.xdg-utils openhandsWeb ];
    };
}