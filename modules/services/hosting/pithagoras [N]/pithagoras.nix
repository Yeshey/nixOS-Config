{ ... }:
{
  flake.modules.nixos.pithagoras =
    { pkgs, config, ... }:
    let
      port = 4100;
      workspacesDir = "/var/lib/pithagoras/workspaces";
      agentDir = "/var/lib/pithagoras/data/home/.pi/agent";
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

        volumes = [
          "/var/lib/pithagoras/data:/data"
          "${workspacesDir}:/workspaces"
          "/var/run/docker.sock:/var/run/docker.sock"
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
        after = [ "pithagoras-config.service" ];
      };

      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];

      services.caddy.virtualHosts."skyloft.tailb6874b.ts.net:9445".extraConfig = ''
        tls internal
        reverse_proxy 127.0.0.1:4100
      '';

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9445 ];
    };
}

# in advanced pane I had to put:
# {
#   "packages": [
#     "npm:pi-provider-litellm"
#   ],
#   "enabledModels": [
#     "litellm/*"
#   ],
#   "defaultProvider": "litellm",
#   "defaultModel": "litellm/weak-fallback-chain",
#   "litellm": {
#     "providers": {
#       "litellm": {
#         "allowInsecureHttp": true
#       }
#     }
#   },
#   "compaction": {
#     "enabled": true,
#     "reserveTokens": 16384,
#     "keepRecentTokens": 20000
#   },
#   "retry": {
#     "enabled": true,
#     "maxRetries": 3
#   }
# }