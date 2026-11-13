{ inputs, ... }:
{
  flake.modules.nixos.strata =
    { pkgs, lib, config, ... }:
    let
      strataPkg = config.services.strata.package;
      keyPath = config.sops.secrets."my-strata-api-key".path;

      # Loads nothing until first request; unloads after 300 s idle.
      serve = pkgs.writeShellScript "strata-serve-lazy" ''
        export STRATA_API_KEY="$(cat "$CREDENTIALS_DIRECTORY/apikey")"
        exec ${strataPkg}/bin/strata-serve \
          --engine strata \
          --config /var/lib/strata/config.json \
          --host ${config.services.strata.host} \
          --port ${toString config.services.strata.port} \
          --lazy \
          --idle-unload 300
      '';
    in
    {
      imports = [ inputs.strata-nix.nixosModules.default ];

      sops.secrets."my-strata-api-key" = {
        owner = "root";
        mode = "0400";
        restartUnits = [ "strata.service" ];
      };

      services.strata = {
        enable = true;
        package = inputs.strata-nix.packages.${pkgs.stdenv.hostPlatform.system}.strata-hip;
        family = "qwen";
        model = "IQ3_S";
        context = 32768;
        host = "0.0.0.0";
        port = 9080;
        apiKeyFile = keyPath;
      };

      systemd.services.strata.serviceConfig = {
        ExecStart = lib.mkForce "${serve}";
        LoadCredential = "apikey:${keyPath}";
      };

      systemd.services.strata.environment.STRATA_ALLOWED_HOSTS =
        "onikao.tailb6874b.ts.net,onikao.tailb6874b.ts.net:9080,onikao,100.74.87.65";

      systemd.services.strata.unitConfig.RequiresMountsFor = keyPath;
    };
}