{ inputs, ... }:
{
  flake.modules.nixos.ollama-cuda = {
    imports = [ inputs.self.modules.nixos.ollama ];
    services.ollama.acceleration = "cuda";
  };
}