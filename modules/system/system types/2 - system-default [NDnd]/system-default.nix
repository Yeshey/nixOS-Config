{
  inputs,
  ...
}:
{
  flake.modules.nixos.system-default = {
    imports = with inputs.self.modules.nixos; [
      system-default-tier
    ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.system-default-tier
    ];
  };
}
