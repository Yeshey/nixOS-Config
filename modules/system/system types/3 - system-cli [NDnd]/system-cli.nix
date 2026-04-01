{
  inputs,
  ...
}:
{
  flake.modules.nixos.system-cli = {
    imports = with inputs.self.modules.nixos; [
      system-cli-tier
    ];
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.system-cli-tier
    ];
  };
}
