{ inputs, ... }:
{
  flake.modules.nixos.ollama-cuda =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.self.modules.nixos.ollama ];
      services.ollama.package = lib.mkForce pkgs.ollama-cuda;
    };
}
