{ inputs, ... }:
{
  flake.modules.nixos.pithagoras =
    { pkgs, config, ... }:
    let
      port = 4100;
      workspacesDir = "/var/lib/pithagoras/workspaces";
      agentDir = "/var/lib/pithagoras/data/home/.pi/agent";
      bolsaDir = "/mnt/OneDrive/ISCTE/Projects/Bolsa";
    in
    {
      sops.secrets."litellm_master_key" = { };
      sops.secrets."forgejo_agent_token" = { };
      sops.secrets."moltbook_api_key" = { };
      sops.secrets."searx_env".restartUnits = [
        "docker-pithagoras.service"
      ];

      sops.templates."pithagoras.env" = {
        content = ''
          OPENAI_API_KEY=${config.sops.placeholder."litellm_master_key"}
          LITELLM_API_KEY=${config.sops.placeholder."litellm_master_key"}
          LITELLM_BASE_URL=http://skyloft.tailb6874b.ts.net:4000/v1
          FORGEJO_WORK_TOKEN=${config.sops.placeholder."forgejo_agent_token"}
          MOLTBOOK_API_KEY=${config.sops.placeholder."moltbook_api_key"}
          WORKSPACES_DIR=/workspaces
          EXECUTOR=host
          PI_PROVIDER=litellm-chat
          PI_MODEL=weak-fallback-chain

          GIT_CONFIG_COUNT=1
          GIT_CONFIG_KEY_0=credential.http://skyloft.tailb6874b.ts.net:3000.helper
          GIT_CONFIG_VALUE_0=!f() { echo username=AGENT_USER; echo password=$FORGEJO_WORK_TOKEN; }; f
          GIT_AUTHOR_NAME=pithagoras
          GIT_AUTHOR_EMAIL=pithagoras@skyloft.tailb6874b.ts.net
          GIT_COMMITTER_NAME=pithagoras
          GIT_COMMITTER_EMAIL=pithagoras@skyloft.tailb6874b.ts.net
        '';
        restartUnits = [ "docker-pithagoras.service" ];
      };

      systemd.tmpfiles.rules = [
        "d ${workspacesDir} 0750 root root -"
      ];

      # /data is a host bind mount. Install config there before starting portal.
      systemd.services.pithagoras-config = {
        description = "Install declarative Pi configuration";

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          ${pkgs.coreutils}/bin/install -Dm600 \
            ${./runner/settings.json} \
            ${agentDir}/settings.json

          ${pkgs.coreutils}/bin/install -Dm600 \
            ${./runner/mcp.json} \
            ${agentDir}/mcp.json

          ${pkgs.coreutils}/bin/install -Dm600 \
            ${./runner/forgejo.json} \
            ${agentDir}/forgejo.json

          ${pkgs.coreutils}/bin/install -Dm600 \
            ${./runner/models.json} \
            ${agentDir}/models.json
        '';
      };

      virtualisation.oci-containers.backend = "docker";
      virtualisation.oci-containers.containers.pithagoras = {
        image = "ghcr.io/yeshey/pithagoras:latest";

        environment = {
          NIX_REMOTE = "daemon";
          NIX_PATH = "nixpkgs=${inputs.nixpkgs.outPath}";
          NIX_CONFIG = "experimental-features = nix-command flakes";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };

        volumes = [
          "/var/lib/pithagoras/data:/data"
          "${workspacesDir}:/workspaces"
          "/var/run/docker.sock:/var/run/docker.sock"
          "${bolsaDir}:${bolsaDir}:rw"
          "/nix:/nix:ro"
          "${config.system.path}/bin:/usr/local/sbin:ro"
        ];

        extraOptions = [
          "--pull=always"
          "--network=host"
          "--env-file=${config.sops.templates."pithagoras.env".path}"
          "--env-file=${config.sops.secrets."searx_env".path}"
        ];
      };

      systemd.services.docker-pithagoras = {
        requires = [ "pithagoras-config.service" ];
        after = [
          "pithagoras-config.service"
          "remote-fs.target"
        ];
        wants = [ "remote-fs.target" ];
      };

      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];

      services.caddy.virtualHosts."skyloft.tailb6874b.ts.net:9445".extraConfig = ''
        tls internal
        reverse_proxy 127.0.0.1:4100
      '';

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9445 ];
    };
}