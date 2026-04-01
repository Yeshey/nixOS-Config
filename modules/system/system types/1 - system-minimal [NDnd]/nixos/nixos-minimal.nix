{
  inputs,
  ...
}:
{
  flake.modules.nixos.nixos-minimal = {
    imports = with inputs.self.modules.nixos; [
      nixos-minimal-tier
    ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.nixos-minimal-tier
    ];
  };
}
