{ inputs, ... }:
{
  flake.modules.nixos.cptr =
    { pkgs, config, lib, ... }:
    let
      port = 11112;
      workspaceDir = "/var/lib/cptr/workspace";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${workspaceDir} 0750 root root -"
      ];

      virtualisation.oci-containers.backend = "docker";
      virtualisation.oci-containers.containers.cptr = {
        image = "ghcr.io/open-webui/computer:browser";
        ports = [ "${toString port}:8000" ];
        volumes = [
          "cptr-data:/data"
          "${workspaceDir}:/workspace"
        ];
        # cmd = [ "--host" "0.0.0.0" ]; # bind beyond localhost inside container
        extraOptions = [ "--pull=missing" ];
      };

      networking.firewall.interfaces.ap0.allowedTCPPorts = [ port ];
    };
}