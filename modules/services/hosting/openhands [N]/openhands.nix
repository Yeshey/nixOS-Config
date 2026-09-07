{ inputs, ... }:
{
  flake.modules.nixos.openhands =
    { pkgs, config, lib, ... }:
    let
      port = 8000;
      home = "/home/yeshey";
      openhandsDir = "${home}/.openhands";
      projectsDir = "${home}/openhands-projects";
      bolsaDataDir = "/mnt/OneDrive/ISCTE/Projects/Bolsa";
      litellmPort = 4000;

      nixCmds = [
        "nix" "nix-shell" "nix-build" "nix-env" "nix-store" "nix-instantiate"
        "nix-channel" "nix-collect-garbage" "nix-copy-closure" "nix-hash" "nix-prefetch-url"
      ];
      wrapperDir = "${openhandsDir}/bin";
      nixpkgsPath = inputs.nixpkgs.outPath;  # pinned store path, matches host flake exactly
    in
    {
      virtualisation.docker.enable = true;
      virtualisation.oci-containers.backend = "docker";

      sops.secrets."github_bolsa_repo_token" = { };
      sops.secrets."litellm_master_key" = { };
      sops.secrets."nvidia_nim_api_key" = { };
      sops.secrets."openrouter" = { };
      sops.secrets."vercel_key" = { };
      sops.secrets."discord_contact_webhook_url" = { };
      sops.secrets."discord_contact_user_id" = { };

      sops.templates."openhands.env" = {
        content = ''
          GITHUB_TOKEN=${config.sops.placeholder."github_bolsa_repo_token"}
          LITELLM_MASTER_KEY=${config.sops.placeholder."litellm_master_key"}
          NVIDIA_NIM_API_KEY=${config.sops.placeholder."nvidia_nim_api_key"}
          OPENROUTER_API_KEY=${config.sops.placeholder."openrouter"}
          VERCEL_API_KEY=${config.sops.placeholder."vercel_key"}
          DISCORD_CONTACT_WEBHOOK_URL=${config.sops.placeholder."discord_contact_webhook_url"}
          DISCORD_CONTACT_USER_ID=${config.sops.placeholder."discord_contact_user_id"}
        '';
        owner = "root";
        mode = "0400";
      };

      virtualisation.oci-containers.containers.openhands = {
        image = "ghcr.io/openhands/agent-canvas:latest";
        autoStart = true;
        environment = {
          LD_LIBRARY_PATH = "";
          LD_PRELOAD = "";
          NIX_REMOTE = "daemon";
        };
        extraOptions = [
          "--rm"
          "--pull=always"
          "--add-host=host.docker.internal:host-gateway"
          "-v" "/var/run/docker.sock:/var/run/docker.sock"
        ];
        ports = [ "0.0.0.0:${toString port}:${toString port}" ];
        volumes =
          [
            "${openhandsDir}:/home/openhands/.openhands"
            "${projectsDir}:/projects"
            "${bolsaDataDir}:${bolsaDataDir}:rw"
            "/nix:/nix:ro"
          ]
          ++ (map (cmd: "${wrapperDir}/${cmd}:/usr/local/bin/${cmd}:ro") nixCmds);
        environmentFiles = [
          config.sops.templates."openhands.env".path
        ];
      };

      systemd.services.docker-openhands = {
        after = [ "remote-fs.target" "network-online.target" "sops-nix.service" ];
        wants = [ "remote-fs.target" "network-online.target" ];
        requires = [ "network-online.target" ];
      };

      systemd.services.openhands-mgr = {
        wantedBy = [ "multi-user.target" "docker-openhands.service" ];
        script = ''
          for d in "${openhandsDir}" "${projectsDir}"; do
            mkdir -p "$d"
            chmod -R 0777 "$d"
          done
          mkdir -p "${bolsaDataDir}"
          chmod 0777 "${bolsaDataDir}"

          mkdir -p "${wrapperDir}"
          for cmd in ${lib.concatStringsSep " " nixCmds}; do
            printf '%s\n' '#!/bin/sh' \
              "export NIX_REMOTE=daemon" \
              "export NIX_PATH=nixpkgs=${nixpkgsPath}" \
              "exec /usr/bin/env -u LD_LIBRARY_PATH -u LD_PRELOAD /nix/var/nix/profiles/system/sw/bin/$cmd \"\$@\"" \
              > "${wrapperDir}/$cmd"
            chmod 755 "${wrapperDir}/$cmd"
          done
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };

      services.caddy = {
        enable = true;
        virtualHosts."10.8.0.1:9443" = {
          extraConfig = ''
            tls internal
            reverse_proxy 127.0.0.1:8000
          '';
        };
      };

      networking.firewall.allowedTCPPorts = [ port 9443 ];

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