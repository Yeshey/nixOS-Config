{
  flake.modules.nixos.minecraft =
    {
      virtualisation.docker.enable = true; # Or change to podman if preferred

        # 2. Run mc-router as a systemd-managed OCI container
        virtualisation.oci-containers = {
          backend = "docker";
          containers.mc-router = {
            image = "itzg/mc-router:latest";
            ports = [
              "25565:25565" # Binds to the default public Minecraft port on your host
            ];
            cmd = [
              "--mapping=tunacraft.yeshey.dpdns.org=127.0.0.1:1207,lopescraft.yeshey.dpdns.org=127.0.0.1:1408,minecraft.yeshey.dpdns.org=127.0.0.1:44329"
            ];
          };
        };

        networking.firewall.allowedTCPPorts = [ 25565 ];
    };
}