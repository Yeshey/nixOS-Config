{ ... }:
{
  flake.modules.nixos.pithagoras =
    { pkgs, config, ... }:
    let
      repoDir = "/var/lib/pithagoras/workspaces/bolsa"; # live checkout, merged main only
    in
    {
      sops.secrets."forgejo_reviewer_token" = { };
      sops.secrets."litellm_master_key" = { }; # same secret litellm.nix declares; see note below
      sops.templates."bolsa-reviewer.env".content = ''
        FORGEJO_REVIEWER_TOKEN=${config.sops.placeholder."forgejo_reviewer_token"}
        LITELLM_API_KEY=${config.sops.placeholder."litellm_master_key"}
      '';

      systemd.services.bolsa-reviewer = {
        description = "Bolsa: review PRs labelled in-review";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" "litellm.service" ];
        path = with pkgs; [ nix git bash coreutils gnugrep gnused ];
        environment = {
          HOME = "/var/lib/bolsa";
          LITELLM_URL = "http://127.0.0.1:4000";
          REVIEWER_MODEL = "weak-fallback-chain";
          NIX_CONFIG = "experimental-features = nix-command flakes";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
        serviceConfig = {
          Type = "oneshot";
          WorkingDirectory = repoDir;
          StateDirectory = "bolsa";
          EnvironmentFile = config.sops.templates."bolsa-reviewer.env".path;
          TimeoutStartSec = "10min";
        };
        script = ''
          exec ${pkgs.python312}/bin/python scripts/reviewer.py
        '';
      };

      systemd.timers.bolsa-reviewer = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:5/10"; # offset from the merge timer
          RandomizedDelaySec = "30s";
        };
      };
    };
}