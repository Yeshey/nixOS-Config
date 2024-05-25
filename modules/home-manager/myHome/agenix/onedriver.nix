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
    # Mount or unmount selected OneDriver account not turned on automatically

    systemd.user.services."onedriverAgenixYeshey" = let 
      mystuff = pkgs.writeShellScriptBin "echo-secret" ''
            mkdir -p "/home/yeshey/.cache/onedriver/${config.myHome.onedriver.serviceName}"
            ${pkgs.coreutils}/bin/cat ${config.age.secrets.onedriver_auth_yeshey.path} > "/home/yeshey/.cache/onedriver/${config.myHome.onedriver.serviceName}/auth_tokens.json" 
          '';
    in {
      Unit = {
        Description = "onedriverAgenixYeshey";

        After = [ "agenix.service" "delete-onedriver-cache.service" ]; 
        Require = [ "agenix.service" ];

        # Afters work, but not Before, the inverse 🤡
        #Before = [ "onedriver@${config.myHome.onedriver.serviceName}.service" ];         
        # Wants and Requires make the service start the other services
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${mystuff}/bin/echo-secret";
      };
      Install.WantedBy = [ "default.target" ]; # "graphical-session.target"  ]; # "default.target"
    };

  };
}
