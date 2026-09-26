{ ... }:
{
  flake.modules.nixos.pithagoras =
    { lib, ... }:
    {
      virtualisation.oci-containers.containers.pithagoras = {
        volumes = lib.mkAfter [
          "/var/run/docker.sock:/var/run/docker.sock"
        ];

        environment.PORTAL_CONTAINER_NAME = "pithagoras";
      };
    };
}