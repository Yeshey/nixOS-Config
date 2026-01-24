{
  inputs,
  withSystem,
  ...
}:
{

  flake.modules.generic.pkgs-by-name =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        inputs.self.overlays.default
      ];
    };

}
