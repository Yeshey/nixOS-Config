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

    environment.systemPackages = with pkgs; [ 
      globalprotect-openconnect
    ];

    services.globalprotect = {
      enable = true;

      # 2.  Portal(s) you want to connect to
      #     (replace with the real Iscte portal)
      settings = {
        "vpn.iscte-iul.pt" = {
          # optional: pass the same openconnect args you would use manually
          openconnect-args = "--protocol=gp --user=jfsaa4@iscte-iul.pt"; # --user=<your_iscte_login>
        };
      };

      # 3.  If Iscte requires a HIP report (most don’t) point to a wrapper
      #     that generates it.  Leave null otherwise.
      csdWrapper = null;
    };

  };
}

# Launch GlobalProtect on App launcher
# go into vpn.iscte-iul.pt
# Fill your credentials