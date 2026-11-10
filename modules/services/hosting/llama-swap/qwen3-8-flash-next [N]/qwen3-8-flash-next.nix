{ inputs, ... }:
{
  flake.modules.nixos.llama-swap-qwen3-8-flash-next =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      systemctl = "${pkgs.systemd}/bin/systemctl";
      keepAlive = pkgs.writeShellScript "strata-ondemand" ''
        ${systemctl} start strata.service
        while ${systemctl} is-active --quiet strata.service; do sleep 5; done
      '';
    in
    {
      imports = [ inputs.strata-nix.nixosModules.default ];

      services.strata = {
        enable = true;
        package = inputs.strata-nix.packages.${pkgs.stdenv.hostPlatform.system}.strata-hip;
        family = "swift";
        model = "IQ3_XXS";
        context = 32768;
        port = 9080;
      };

      # Loaded only when llama-swap asks.
      systemd.services.strata.wantedBy = lib.mkForce [ ];

      # Let llama-swap start/stop this one unit.
      security.polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              action.lookup("unit") == "strata.service" &&
              subject.user == "llama-swap") {
            return polkit.Result.YES;
          }
        });
      '';

      services.llama-swap.settings.models."qwen3-8-flash-next" = {
        proxy = "http://127.0.0.1:${toString config.services.strata.port}";
        cmd = "${keepAlive}";
        cmdStop = "${systemctl} stop strata.service";
        checkEndpoint = "/v1/models";
        ttl = 300;
      };
    };
}