{
  flake.modules.nixos.docker = {
    virtualisation.docker.enable = true;
    virtualisation.podman.enable = true;
  };
}