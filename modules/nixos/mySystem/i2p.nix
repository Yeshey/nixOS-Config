{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.i2p;
in
{
  options.mySystem.i2p = with lib; {
    enable = mkEnableOption "i2p";
  };

  config = lib.mkIf cfg.enable {

    # http://127.0.0.1:7657/welcome
    services.i2p = {
      enable = true;
    };

  };
}

