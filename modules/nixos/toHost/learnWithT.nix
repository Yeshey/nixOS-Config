{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.toHost.learnWithT;
in
{
  imports = [
    inputs.learnWithT.nixosModules.default # what to add here????
  ];

  options.toHost.learnWithT = {
    enable = (lib.mkEnableOption "learnWithT");
  };

  config = lib.mkIf cfg.enable {

    learnWithT = {
      enable = true;
      development.openPorts.enable = true;
    };

  };
}
