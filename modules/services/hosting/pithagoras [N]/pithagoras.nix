{ inputs, ... }:
{
  flake.modules.nixos.pithagoras =
    { pkgs, config, lib, ... }:
    let
      port = 4100;
      workspacesDir = "/var/lib/pithagoras/workspaces";
      runnerContext = ./runner;
    in
    {
      sops.secrets."openrouter" = { };
      sops.secrets."litellm_master_key" = { };
      sops.secrets."forgejo_agent_token" = { };

      sops.templates."pithagoras.env" = {
        # PI_IMAGE=ghcr.io/yeshey/pithagoras:latest
        content = ''
          OPENAI_API_KEY=${config.sops.placeholder."litellm_master_key"}
          FORGEJO_WORK_TOKEN=${config.sops.placeholder."forgejo_agent_token"}
          WORKSPACES_DIR=/workspaces
          PORTAL_CONTAINER_NAME=pithagoras
          EXECUTOR=container
          PI_IMAGE=pithagoras-runner:local
          PI_PROVIDER=litellm
          PI_MODEL=weak-fallback-chain
          LITELLM_BASE_URL=http://skyloft.tailb6874b.ts.net:4000/v1
          LITELLM_API_KEY=${config.sops.placeholder."litellm_master_key"}
        '';
        restartUnits = [ "docker-pithagoras.service" ];
      };

      systemd.tmpfiles.rules = [
        "d ${workspacesDir} 0750 root root -"
      ];

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
        ];
      };

      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];

      services.caddy.virtualHosts."skyloft.tailb6874b.ts.net:9445".extraConfig = ''
        tls internal
        reverse_proxy 127.0.0.1:4100
      '';

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9445 ];



      systemd.services.pithagoras-runner-image = {
        description = "Build Pithagoras task runner image";
        requires = [ "docker.service" ];
        after = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.docker}/bin/docker build --pull -t pithagoras-runner:local ${runnerContext}";
        };
      };

      systemd.services.docker-pithagoras = {
        requires = [ "pithagoras-runner-image.service" ];
        after = [ "pithagoras-runner-image.service" ];
      };
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