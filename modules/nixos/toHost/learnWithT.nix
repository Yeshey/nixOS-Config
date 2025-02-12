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
      development.openPorts.enable = true;
      appwrite = {
        enable = true;
      };
    };

  };
}
