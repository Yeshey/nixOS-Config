{ inputs, ... }:
{
  flake.modules.nixos.sops-base = {
    imports = with inputs.self.modules.nixos; [
      sops-nix
    ];
  };
}