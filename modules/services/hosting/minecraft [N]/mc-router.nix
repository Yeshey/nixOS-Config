{ inputs, ... }:
{
  flake.modules.nixos.minecraft =
    {
      # See service with journalctl -fu docker-mc-router.service
      virtualisation.docker.enable = true; # Or change to podman if preferred
      
      virtualisation.oci-containers = {
        backend = "docker";
        containers.mc-router = {
          image = "itzg/mc-router:latest";
          
          extraOptions = [ "--network=host" ];
          
          cmd = [
            "--mapping=tunacraft.yeshey.dpdns.org=127.0.0.1:1207,lopescraft.yeshey.dpdns.org=127.0.0.1:1408,minecraft.yeshey.dpdns.org=127.0.0.1:44329"
          ];
        };
      };
      
      networking.firewall.allowedTCPPorts = [ 25565 ];
    };
}