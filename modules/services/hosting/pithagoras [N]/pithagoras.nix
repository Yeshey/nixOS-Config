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

      sops.templates."pithagoras.env".content = ''
        WORKSPACES_DIR=${workspacesDir}
        EXECUTOR=host
        PI_PROVIDER=openrouter
        PI_MODEL=anthropic/claude-sonnet-5
        OPENROUTER_API_KEY=${config.sops.placeholder."openrouter"}
      '';

      systemd.tmpfiles.rules = [
        "d ${workspacesDir} 0750 root root -"
      ];

      virtualisation.oci-containers.backend = "docker"; # match rest of config
      virtualisation.oci-containers.containers.pithagoras = {
        image = "ghcr.io/yeshey/pithagoras:latest"; # pin sha, bump manually on update
        volumes = [ "${workspacesDir}:${workspacesDir}" ];
        extraOptions = [ "--network=host" ]; # required — upstream design, pi expects host-net services
      };

      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];
    };
}