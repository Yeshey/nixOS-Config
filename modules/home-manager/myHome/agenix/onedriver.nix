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

    systemd.user.services."onedriverAgenixYeshey" = let 
      mystuff = pkgs.writeShellScriptBin "echo-secret" ''
            mkdir -p "/home/yeshey/.cache/onedriver/${config.myHome.onedriver.serviceName}"
            ${pkgs.coreutils}/bin/cat ${config.age.secrets.onedriver_auth.path} > "/home/yeshey/.cache/onedriver/${config.myHome.onedriver.serviceName}/auth_tokens.json" 
          '';
    in {
      Unit = {
        Description = "onedriverAgenixYeshey";

        After = [ "agenix.service" ]; 
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${mystuff}/bin/echo-secret";
      };
      Install.WantedBy = [ "graphical-session.target"  ]; # "default.target"
    };

  };
}
