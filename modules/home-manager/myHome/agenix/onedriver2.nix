{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.myHome.agenix.onedriver2;
in
{
  options.myHome.agenix.onedriver2 = with lib; {
    enable = mkEnableOption "onedriverAgenix";
    ageOneDriverAuthFile = mkOption {
      type = types.str;
      example = config.age.secrets.onedriver_auth_isec_yeshey.path;
    };
  };

  config = lib.mkIf (config.myHome.enable && config.myHome.agenix.enable && cfg.enable) {
    # Mount or unmount selected OneDriver account not turned on automatically

    systemd.user.services."onedriverAgenixYeshey2" = let 
      mystuff2 = pkgs.writeShellScriptBin "echo-secret2" ''
            ${pkgs.coreutils}/bin/mkdir -p "/home/yeshey/.cache/onedriver/${config.myHome.onedriver2.serviceCoreName}"
            ${pkgs.coreutils}/bin/cat ${cfg.ageOneDriverAuthFile} > "/home/yeshey/.cache/onedriver/${config.myHome.onedriver2.serviceCoreName}/auth_tokens.json" 
          '';
    in {
      Unit = {
        Description = "onedriverAgenixYeshey2";

        After = [ "agenix.service" "delete-onedriver-cache2.service" ]; 

        # Afters work, but not Before, the inverse 🤡
        #Before = [ "onedriver@${config.myHome.onedriver.serviceCoreName}.service" ];         
        # Wants and Requires make the service start the other services
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${mystuff2}/bin/echo-secret2";
      };
      Install.WantedBy = [ "default.target" ]; # "graphical-session.target"  ]; # "default.target"
    };

    systemd.user.services."delete-onedriver-cache2" = let
      script = pkgs.writeShellScriptBin "delete-onedriver-cache-script" ''
            ${pkgs.onedriver}/bin/onedriver --wipe-cache

            # if setting agenix keys, set'em afterwards
            ${lib.strings.optionalString config.myHome.agenix.onedriver2.enable "mkdir -p '/home/yeshey/.cache/onedriver/${config.myHome.onedriver2.serviceCoreName}'"}
            ${lib.strings.optionalString config.myHome.agenix.onedriver2.enable "${pkgs.coreutils}/bin/cat ${config.age.secrets.onedriver_auth_iscte_yeshey.path} > '/home/yeshey/.cache/onedriver/${config.myHome.onedriver2.serviceCoreName}/auth_tokens.json'"}
          '';
    in {
      Service = { 
        ExecStart = lib.mkIf config.myHome.onedriver2.enable (lib.mkForce "${script}/bin/delete-onedriver-cache-script");
      };
    };

  };
}
