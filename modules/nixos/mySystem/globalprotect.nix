{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.globalprotect;
in
{
  options.mySystem.globalprotect = {
    enable = lib.mkEnableOption "globalprotect";
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {  

    # environment.systemPackages = [ 
    #   inputs.globalprotect-openconnect.packages.${pkgs.system}.default
    # ];

  };
}

# Launch GlobalProtect on App launcher
# go into vpn.iscte-iul.pt
# Fill your credentials