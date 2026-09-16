{ inputs, ... }:
{
  flake.modules.nixos.pithagoras =
    { pkgs, config, lib, ... }:
    let
      port = 4100;
      workspacesDir = "/var/lib/pithagoras/workspaces";
    in
    {
      sops.secrets."openrouter" = { };
      sops.secrets."litellm_master_key" = { };

      sops.templates."pithagoras.env" = {
        content = ''
          WORKSPACES_DIR=${workspacesDir}
          EXECUTOR=host
          PI_PROVIDER=litellm
          PI_MODEL=weak-fallback-chain
          LITELLM_BASE_URL=http://skyloft.tailb6874b.ts.net:4000
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
        volumes = [ "${workspacesDir}:${workspacesDir}" ];
        extraOptions = [
          "--pull=always"
          "--network=host"
          "--env-file=${config.sops.templates."pithagoras.env".path}"
        ];
      };

      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];
    };
}