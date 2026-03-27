{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = [
    # inputs.plasma-manager.homeModules.plasma-manager # 
    # inputs.plasma-manager.flakeModules.home-manager # Doesn't support flakeModules, have to import in plasma-customisation.nix directly as I understand it #
  ];
}
