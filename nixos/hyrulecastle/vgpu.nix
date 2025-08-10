# thanks to https://github.com/MakiseKurisu/nixos-config/blob/main/modules/nvidia-vgpu.nix
{
  vgpu4nixos,
  fastapi-dls-nixos,
  config,
  pkgs,
  lib,
  ...
}:

{

  
  environment.etc.specialisation.text = "vgpu";

}
