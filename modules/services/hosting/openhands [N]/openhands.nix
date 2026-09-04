{ inputs, ... }:
{
  flake.modules.nixos.openhands =
    { pkgs, config, ... }:
    let
      port = 8000;
      home = "/home/yeshey";
      openhandsDir = "${home}/.openhands";
      projectsDir = "${home}/openhands-projects";
      nixStoreDir = "${home}/openhands-nix-store";
      bolsaDataDir = "/mnt/OneDrive/ISCTE/Projects/Bolsa";
      litellmPort = 4000; # must match modules/services/hosting/litellm [N]/litellm.nix
    in
    {
      virtualisation.docker.enable = true;
      virtualisation.oci-containers.backend = "docker";

      sops.secrets."github_bolsa_repo_token" = { };
      sops.secrets."litellm_master_key" = { };

      sops.templates."openhands.env" = {
        # Giving it access to my Bolsa repository
        content = ''
          GITHUB_TOKEN=${config.sops.placeholder."github_bolsa_repo_token"} 
        '';
        owner = "root";
        mode = "0400";
      };

      virtualisation.oci-containers.containers.openhands = {
        image = "ghcr.io/openhands/agent-canvas:1.16.0";
        autoStart = true;
        extraOptions = [
          "--rm"
          "--pull=always"
          "--add-host=host.docker.internal:host-gateway"
          "-v" "/var/run/docker.sock:/var/run/docker.sock"
        ];
        ports = [ "0.0.0.0:${toString port}:${toString port}" ];
        volumes = [
          "${openhandsDir}:/home/openhands/.openhands"
          "${projectsDir}:/projects"
          "${bolsaDataDir}:${bolsaDataDir}:rw" # agents can now access /mnt/OneDrive/ISCTE/Projects/Bolsa
          "${nixStoreDir}:/nix:rw"
        ];
        environmentFiles = [ config.sops.templates."openhands.env".path ];
      };

      systemd.services.docker-openhands = {
        after = [ "remote-fs.target" "network-online.target" "sops-nix.service" ];
        wants = [ "remote-fs.target" "network-online.target" ];
        requires = [ "network-online.target" ];
      };

      systemd.services.openhands-mgr = {
        wantedBy = [ "multi-user.target" "docker-openhands.service" ];
        script = ''
          for d in "${openhandsDir}" "${projectsDir}" "${nixStoreDir}"; do
            echo "Ensuring $d exists..."
            mkdir -p "$d"
            chmod -R 0777 "$d"
          done
          mkdir -p "${bolsaDataDir}"
          chmod 0777 "${bolsaDataDir}"
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