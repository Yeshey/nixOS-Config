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
        # After = [ "agenix.service" ];

        #Wants = [ "local-fs.target" "remote-fs.target" "network.target" "network-online.target" "nss-lookup.target" "systemd-resolved.service" ];
        After = [ "agenix.service" ]; # "local-fs.target" "remote-fs.target" "network.target" "network-online.target" "nss-lookup.target" "systemd-resolved.service" ]; # will run before network turns of, bc in shutdown order is reversed
        # Before = [ "onedriver@mnt-hdd\x2dbtrfs-Yeshey-OneDriver.service" ];
        #Requires = [ "local-fs.target" "remote-fs.target" "network.target" "network-online.target" "nss-lookup.target" "systemd-resolved.service" ];

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
      Install.WantedBy = [ "graphical-session.target"  ]; # "default.target"
    };

  };
}
