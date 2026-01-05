{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.vnstat;
in
{
  options.toHost.vnstat = {
    enable = lib.mkEnableOption "vnstat network bandwidth monitoring";
  };

  config = lib.mkMerge [
    
    (lib.mkIf (cfg.enable) {
      services.vnstat.enable = true;
    })
    
    (lib.mkIf (cfg.enable && config.mySystem.impermanence.enable) {
      environment.persistence."/persistent" = {
        directories = [
          { 
            directory = "/var/lib/vnstat"; 
            user = "vnstatd"; 
            group = "vnstatd"; 
            mode = "0755";
          }
        ];
      };
    })
  ];
}