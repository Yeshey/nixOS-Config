{ inputs, ... }:
{
  flake.modules.nixos.t3code =
    { pkgs, lib, ... }:
    {
      users.users.t3code = {
        isSystemUser = true;
        group = "t3code";
        home = "/var/lib/t3code";
        createHome = true;
      };
      users.groups.t3code = { };

      systemd.services.t3code = {
        description = "T3 Code headless server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        # npx needs node + git; agent CLIs (codex/claude) must be on PATH too
        path = [ pkgs.nodejs pkgs.git pkgs.bash pkgs.coreutils pkgs.gnutar pkgs.gzip ];
        environment = {
          HOME = "/var/lib/t3code";
          NPM_CONFIG_CACHE = "/var/lib/t3code/.npm";
        };

        serviceConfig = {
          User = "t3code";
          Group = "t3code";
          WorkingDirectory = "/var/lib/t3code";
          # pin a version instead of @latest once it works
          ExecStart = "${lib.getExe' pkgs.nodejs "npx"} --yes t3@latest serve --host 127.0.0.1 --port 3773";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
}