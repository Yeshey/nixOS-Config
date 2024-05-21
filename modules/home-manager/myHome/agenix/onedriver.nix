{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.myHome.agenix.onedriver;
in
{
  options.myHome.agenix.onedriver = with lib; {
    enable = mkEnableOption "onedriverAgenix";
  };

  config = lib.mkIf cfg.enable {

    # DOESNT FUCKING WORK, GETS WIPED OUT BY MY OTHER SERVICE
    systemd.user.services."onedriverAgenixYeshey" = let 
      mystuff = pkgs.writeShellScriptBin "echo-secret" ''
            mkdir -p "/home/yeshey/.cache/onedriver/${config.myHome.onedriver.serviceName}"
            ${pkgs.coreutils}/bin/cat ${config.age.secrets.onedriver_auth.path} > "/home/yeshey/.cache/onedriver/${config.myHome.onedriver.serviceName}/auth_tokens.json" 
          '';
    in {
      Unit = {
        Description = "onedriverAgenixYeshey";
        After = [ "agenix.service" ];
        # non of this shit works, so I had to also add it to the service in normal onedrive
        #After = [ "agenix.service delete-onedriver-cache.service" ];#"delete-onedriver-cache.service" ];
        #Requires = [ "agenix.service delete-onedriver-cache.service" ];#"delete-onedriver-cache.service" ];
        #RequiredBy = "delete-onedriver-cache.service";
        #Wants = [ "agenix.service" ];#"delete-onedriver-cache.service" ];
        #Before = [ config.myHome.onedriver.serviceName ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${mystuff}/bin/echo-secret";
      };
      Install.WantedBy = [ "default.target" ];
    };

  };
}
