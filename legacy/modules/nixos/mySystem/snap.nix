{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.snap;
in
{
  options.mySystem.snap = with lib; {
    enable = mkEnableOption "snap";
  };

  imports = [
    inputs.nix-snapd.nixosModules.default
  ];

  # always active lib.mkIf (config.mySystem.enable && cfg.enable) 
  config = lib.mkIf (config.mySystem.enable && cfg.enable) { 

    services.snap.enable = true;

  };
}
